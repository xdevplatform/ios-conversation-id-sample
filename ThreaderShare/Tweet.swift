//
//  Tweet.swift
//  threadshare
//
//  Created by Daniele Bernardi on 10/15/20.
//

import Foundation

func request(url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> Void {
  
  guard let settingsPath = Bundle.main.path(forResource: "TwitterSettings", ofType: "plist"),
        let xml = FileManager.default.contents(atPath: settingsPath),
        let plist = try? PropertyListDecoder().decode(TwitterSettings.self, from: xml) else {
    completionHandler(nil, nil, TwitterRequestError.missingBearerToken)
    return
  }

  let bearerToken = plist.bearerToken

  var request = URLRequest(url: url)
  request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

  URLSession.shared.dataTask(with: request, completionHandler: completionHandler).resume()  
}

func requestURL(path: String) -> URLComponents {
  let defaultParams = [
    URLQueryItem(name: "tweet.fields", value: "attachments,conversation_id,author_id,in_reply_to_user_id,entities,created_at"),
    URLQueryItem(name: "user.fields", value: "profile_image_url"),
    URLQueryItem(name: "media.fields", value: "url,preview_image_url"),
    URLQueryItem(name: "expansions", value: "attachments.media_keys,attachments.poll_ids,referenced_tweets.id,in_reply_to_user_id,author_id")
  ]
  
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.twitter.com"
  components.path = path
  components.queryItems = defaultParams
  
  return components
}

extension Tweet {
  static func thread(id: String, completionBlock: @escaping (TweetLookupResponse?, TwitterRequestError?) -> Void) {

    var url = requestURL(path: "/2/tweets")
    url.queryItems?.append(URLQueryItem(name: "ids", value: id))
    
    DispatchQueue.global(qos: .utility).async {
      let result = Twitter.request(url: url.url!)
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          // Check tweet is recent
          if let response = response,
             let tweet = response.data?.first,
             tweet.isOlderThanSevenDays == false {
            return .success(response)
          }
          
          return .failure(.oldTweet)
        }
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          var url = requestURL(path: "/2/tweets/search/recent")
          let tweet = response!.data!.first!
          url.queryItems?.append(URLQueryItem(name: "query", value: "from:\(tweet.authorId) to:\(tweet.authorId) conversation_id:\(tweet.conversationId)"))
          return Twitter.request(url: url.url!)
        }
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          var result: Result<TweetLookupResponse?, TwitterRequestError>!
          
          var url = requestURL(path: "/2/tweets")
          if let response = response,
             let data = response.data {
            var ids = data.map { $0.id }
            ids.append(id)
            url.queryItems?.append(URLQueryItem(name: "ids", value: ids.joined(separator: ",")))
            return Twitter.request(url: url.url!)
          } else {
            result = .failure(.unknown)
            return result
          }
        }
        
      DispatchQueue.main.async {
        switch result {
          case let .success(data):
            if var thread = data {
              thread.data?.sort { $0.id.compare($1.id) == .orderedAscending }
              completionBlock(thread, nil)
            } else {
              completionBlock(nil, .conversationNotFound)
            }
              
          case let .failure(error):
              completionBlock(nil, error)
        }
      }
    }
  }
}
