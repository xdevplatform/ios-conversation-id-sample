//
//  Tweet.swift
//  threadshare
//
//  Created by Daniele Bernardi on 10/15/20.
//

import Foundation

enum TwitterRequestError: Error {
  case missingBearerToken
  case unknown
}

struct TwitterSettings : Codable {
  var bearerToken: String
}

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

let defaultParams = [
  URLQueryItem(name: "tweet.fields", value: "attachments,conversation_id,author_id,in_reply_to_user_id,entities,context_annotations,created_at"),
  URLQueryItem(name: "user.fields", value: "profile_image_url"),
  URLQueryItem(name: "media.fields", value: "url,preview_image_url"),
  URLQueryItem(name: "expansions", value: "attachments.media_keys,attachments.poll_ids,referenced_tweets.id,in_reply_to_user_id,author_id")
]

extension Tweet {
  func referenceURL(type: ReferencedTweet.ReferenceType) -> URL? {
    if let references = referencedTweets,
       let tweetReference = references.first(where: { (referencedTweet) -> Bool in
        return referencedTweet.type == type
       }) {

      return URL(string: "https://twitter.com/t/status/\(tweetReference.id)")!
    }

    return nil
  }
}

extension SingleTweetResponse {
  func user() -> User? {
    return includes?.users?.first(where: { (user) -> Bool in
      user.id == data?.authorId
    })
  }
}

extension TweetSearchResponse {
  func media(tweet: Tweet) -> [Media]? {
    if let attachments = tweet.attachments,
       let mediaKeys = attachments.mediaKeys,
       let includes = self.includes,
       let media = includes.media {
      return media.filter { (item) -> Bool in
        return mediaKeys.contains(item.mediaKey)
      }
    }
    return nil
  }
  
  func poll(tweet: Tweet) -> Poll? {
    if let attachments = tweet.attachments,
       let pollId = attachments.pollIds?.first,
       let includes = self.includes,
       let polls = includes.polls {
      return polls.filter { $0.id == pollId }.first
    }
    return nil
  }
}

func decode<T: Decodable>(_ json: Data) throws -> T {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
  
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .formatted(formatter)
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return try decoder.decode(T.self, from: json)
}

extension Tweet {
  static func tweet(id: String, completionBlock: @escaping (Tweet?, SingleTweetResponse?, Error?) -> Void) {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.twitter.com"
    components.path = "/2/tweets/\(id)"
    components.queryItems = defaultParams
    
    let lookupURL = components.url!
    
    request(url: lookupURL) { (body, response, error) in
      if let error = error {
        completionBlock(nil, nil, error)
        return
      }
      
      if let body = body,
         let json: SingleTweetResponse = try? decode(body),
         let data = json.data {
        completionBlock(data, json, nil)
      } else {
        print("Cannot find original conversation.")
        completionBlock(nil, nil, TwitterRequestError.unknown)
      }
    }
  }
  
  static func checkAvailability(tweets: TweetSearchResponse, completionBlock: @escaping (TweetSearchResponse?, Error?) -> Void) -> Void {
    
    guard let data = tweets.data else {
      completionBlock(nil, nil)
      return
    }
    
    let ids = data.map { $0.id }
    
    guard ids.count > 0 else {
      completionBlock(nil, nil)
      return
    }
    
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.twitter.com"
    components.path = "/2/tweets"
    components.queryItems = defaultParams + [
      URLQueryItem(name: "ids", value: ids.joined(separator: ","))
    ]
    
    let lookupURL = components.url!
    request(url: lookupURL) { (body, _, error) in
      if let error = error {
        completionBlock(nil, error)
        return
      }
      
      if let body = body,
         let response: TweetSearchResponse = try? decode(body),
         let tweets = response.data {
        var availableTweets = response
        availableTweets.data = tweets.filter {
          ids.contains($0.id)
        }
        
        completionBlock(availableTweets, nil)
        
      } else {
        completionBlock(nil, TwitterRequestError.unknown)
      }
    }
  }
    
  static func thread(tweet: Tweet, completionBlock: @escaping ([Tweet]?, TweetSearchResponse?, Error?) -> Void) {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.twitter.com"
    components.path = "/2/tweets/search/recent"
    components.queryItems = defaultParams + [
      URLQueryItem(name: "query", value: "conversation_id:\(tweet.conversationId) from:\(tweet.authorId)"),
      URLQueryItem(name: "max_results", value: "100")
    ]
    
    let threadSearchURL = components.url!
    
    if let fileManager = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
       let body = try? Data(contentsOf: fileManager.appendingPathComponent("\(tweet.id).json")),
       let cachedResponse: TweetSearchResponse = try? decode(body) {
      
      checkAvailability(tweets: cachedResponse) { (response, error) in
        if let error = error {
          completionBlock(nil, nil, error)
          return
        }
        
        if let response = response,
           let conversation = response.data,
           let includes = response.includes,
           let includedTweets = includes.tweets {
          var thread = conversation.filter { $0.authorId == $0.inReplyToUserId }
          let originalConversationTweets = includedTweets.filter { $0.id == tweet.conversationId }
          
          if let originalConversationTweet = originalConversationTweets.first {
            thread.append(originalConversationTweet)
          }
          
          thread.sort { $0.id.compare($1.id) == .orderedAscending }
          
          completionBlock(thread, response, nil)
        } else {
          completionBlock(nil, nil, TwitterRequestError.unknown)
        }
      }

      return
    }
    
    request(url: threadSearchURL) { (body, _, error) in
      if let error = error {
        completionBlock(nil, nil, error)
        return
      }
      
      if let body = body,
         let response: TweetSearchResponse = try? decode(body),
         let conversation = response.data,
         let includes = response.includes,
         let includedTweets = includes.tweets {
        
        if let fileManager = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
          let cacheFile = fileManager.appendingPathComponent("\(tweet.id).json")
          try? body.write(to: cacheFile, options: .atomicWrite)
        }
        
        var thread = conversation.filter { $0.authorId == $0.inReplyToUserId }
        let originalConversationTweets = includedTweets.filter { $0.id == tweet.conversationId }
        
        if let originalConversationTweet = originalConversationTweets.first {
          thread.append(originalConversationTweet)
        }
        
        thread.sort { $0.id.compare($1.id) == .orderedAscending }
        
        completionBlock(thread, response, nil)
      } else {
        completionBlock(nil, nil, nil)
      }
    }
  }
}
