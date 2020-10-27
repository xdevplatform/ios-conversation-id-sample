//
//  ThreadHeader.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/23/20.
//

import SwiftUI

struct ThreadHeader: View {
  var thread: TweetLookupResponse
  @ViewBuilder
  var body: some View {
    if let tweet = thread.conversationHead,
       let user = thread.user(of: tweet) {
      HStack() {
        UserImage(user: user)
        VStack(alignment: .leading) {
          Text(user.name).fontWeight(.bold).lineLimit(1)
          Text("@ \(user.username)").font(.caption).foregroundColor(.secondary).lineLimit(1)
          Spacer().frame(height: 5)
          Text(formatTweetCreationDate(tweet: thread.conversationHead!)).lineLimit(1)
        }
      }.padding()
    }
  }
}

extension ThreadHeader {
  func formatTweetCreationDate(tweet: Tweet) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: tweet.createdAt)
  }
}

struct ThreadRow_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ThreadHeader(thread: mockThreads[0])
      ThreadHeader(thread: mockThreads[1])
    }.previewLayout(.fixed(width: 400, height: 86))
    
  }
}
