//
//  Models+Extension.swift
//  ThreaderShare
//
//  Created by Daniele Bernardi on 10/21/20.
//

import Foundation

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

extension TweetLookupResponse {
  func conversationHead() -> Tweet? {
    return data?.first { $0.id == $0.conversationId }
  }
  
  func user(of tweet: Tweet) -> User? {
    return includes?.users?.first { $0.id == tweet.authorId }
  }

  func media(tweet: Tweet) -> [Media]? {
    if let mediaKeys = tweet.attachments?.mediaKeys,
       let media = self.includes?.media {
      return media.filter { (item) -> Bool in
        return mediaKeys.contains(item.mediaKey)
      }
    }
    return nil
  }
  
  func poll(tweet: Tweet) -> Poll? {
    if let pollId = tweet.attachments?.pollIds?.first,
       let polls = self.includes?.polls {
      return polls.filter { $0.id == pollId }.first
    }
    return nil
  }
}
