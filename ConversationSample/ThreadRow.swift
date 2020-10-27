//
//  ThreadRow.swift
//  Threader
//
//  Created by Daniele Bernardi on 10/23/20.
//

import SwiftUI
import URLImage

struct ThreadHeader: View {
  var thread: TweetLookupResponse
  var body: some View {
    HStack() {
      URLImage(url: URL(string: user.profileImageUrl)!) { $0
          .resizable().aspectRatio(contentMode: .fit)
      }.frame(width: 86, height: 86, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/).clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
      VStack(alignment: .leading) {
        Text(user.name).fontWeight(.bold).lineLimit(1)
        Text("@ \(user.username)").font(.caption).foregroundColor(.secondary).lineLimit(1)
        Spacer().frame(height: 5)
        Text(formatTweetCreationDate(tweet: thread.conversationHead!)).lineLimit(1)
      }
    }.padding()
  }
}

extension ThreadHeader {
  func formatTweetCreationDate(tweet: Tweet) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: tweet.createdAt)
  }


  var formattedTweet: String {
    let tweet = thread.conversationHead!
    var text = tweet.text
    tweet.entities?.urls?.forEach {
      text = text.replacingOccurrences(of: $0.url, with: "")
    }
    
    return text
      .replacingOccurrences(of: "\n", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  var user: User {
    return thread.user(of: thread.conversationHead!)!
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
