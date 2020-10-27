//
//  MockData.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/23/20.
//

import Foundation

struct MockData {
  static let user = User(
    id: "1",
    name: "Twitter Dev",
    username: "TwitterDev",
    profileImageUrl: "https://pbs.twimg.com/profile_images/1283786620521652229/lEODkLTh_normal.jpg")
  
  static let media = Media(
    mediaKey: "1",
    type: .photo,
    url: "https://thiscatdoesnotexist.com")
  
  static let poll = Poll(id: "1", options: [
    PollOption(position: 1, label: "Option 1", votes: 10),
    PollOption(position: 2, label: "Option 2", votes: 20),
    PollOption(position: 3, label: "Option 3", votes: 30),
    PollOption(position: 4, label: "Option 4", votes: 4),
  ]);
  
  static let includes = Includes(
    media: [media],
    users: [user],
    polls: [poll])
  
  static var searchResponse: TweetLookupResponse {
    var data: [Tweet] = []
    for id in 0..<30 {
      var attachments: Attachments? = nil
      if id == 1 {
        attachments = Attachments(mediaKeys: ["1"])
      }
      
      if id == 3 {
        attachments = Attachments(mediaKeys: ["1"], pollIds: ["1"])
      }

      if id == 5 {
        attachments = Attachments(pollIds: ["1"])
      }

      if id == 7 {
        attachments = Attachments(mediaKeys: ["1", "1", "1"])
      }

      
      let date = Calendar.current.date(byAdding: .second, value: id, to: Date())!
      data.append(Tweet(attachments: attachments, authorId: "1", conversationId: "1", createdAt: date, entities: nil, id: "\(id)", inReplyToUserId: "1", referencedTweets: nil, text: "Tweet #\(id) in conversation"))

    }
    
    return TweetLookupResponse(data: data, includes: includes, meta: nil)
  }
}
