//
//  Models+Extension.swift
//  ConversationSampleShare
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
  var conversationHead: Tweet? {
    return data?.first { $0.id == $0.conversationId }
      ?? includes?.tweets?.first { $0.id == $0.conversationId }
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

extension Poll {
  var totalVotes: Int {
    options.reduce(0) { $0 + $1.votes }
  }
  
  func option(position: Int) -> PollOption? {
    options.first { $0.position == position }
  }
  
  func percentValue(position: Int) -> Float {
    guard let poll = option(position: position),
          totalVotes > 0 else {
      return 0.0
    }
    
    return Float(poll.votes) / Float(totalVotes)
  }
  
  func percentLabel(position: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    return formatter.string(from: NSNumber(value: percentValue(position: position)))!
  }
  
  func isLeading(position: Int) -> Bool {
    let max = options
      .sorted { a, b in a.votes < b.votes }
      .max { a, b in a.votes < b.votes }!
    return max.position == position
  }
}
