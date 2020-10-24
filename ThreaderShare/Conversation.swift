//
//  Tweet.swift
//  threadshare
//
//  Created by Daniele Bernardi on 10/15/20.
//

import Foundation

class Conversation {
  private var id: String
  private var conversationHead: Tweet!
  
  init(of id: String) {
    self.id = id
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

  func thread(_ completionBlock: @escaping (TweetLookupResponse?, TwitterRequestError?) -> Void) {
    
    DispatchQueue.global(qos: .utility).async {
      var url = self.requestURL(path: "/2/tweets")
      url.queryItems?.append(URLQueryItem(name: "ids", value: self.id))
      
      // Get the selected tweet
      let result = Twitter.request(url: url.url!, cached: false)

        // Get the conversation ID from the selected tweet
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          guard let tweet = response?.data?.first else {
            return .failure(.tweetNotFound)
          }
          
          if tweet.id == tweet.conversationId {
            return .success(response)
          } else {
            var url = self.requestURL(path: "/2/tweets")
            url.queryItems?.append(URLQueryItem(name: "ids", value: tweet.conversationId))
            return Twitter.request(url: url.url!, cached: false)
          }
        }
        
        // Check that the conversation is recent
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          guard let tweet = response?.data?.first else {
            return .failure(.conversationNotFound)
          }
          
          self.conversationHead = tweet
          guard self.conversationHead.isOlderThanSevenDays == false else {
            return .failure(.tweetTooOld)
          }
          
          return .success(response)
        }
        
        // Get the entire thread using recent search
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          var url = self.requestURL(path: "/2/tweets/search/recent")
          url.queryItems? += [
            URLQueryItem(name: "query", value: "from:\(self.conversationHead.authorId) to:\(self.conversationHead.authorId) conversation_id:\(self.conversationHead.conversationId)"),
            URLQueryItem(name: "max_results", value: "100")
          ]
          return Twitter.request(url: url.url!)
        }

        // Get individual tweets from the thread.
        // Since we're caching the search response, this is useful to check that
        // each tweet in the thread still exists.
        .flatMap { (response) -> Result<TweetLookupResponse?, TwitterRequestError> in
          var url = self.requestURL(path: "/2/tweets")
          if let data = response?.data {
            var ids = data.map { $0.id }
            ids.append(self.conversationHead.id)
            url.queryItems?.append(URLQueryItem(name: "ids", value: ids.joined(separator: ",")))
            return Twitter.request(url: url.url!, cached: false)
          } else {
            return .failure(.unknown)
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
