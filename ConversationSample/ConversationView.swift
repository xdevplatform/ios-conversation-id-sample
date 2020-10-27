//
//  SwiftUIView.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/23/20.
//

import SwiftUI

struct ConversationView: View {
  var thread: TweetLookupResponse
    var body: some View {
      ScrollView() {
        ThreadHeader(thread: thread)
        VStack(alignment: .leading, spacing: 10) {
          ForEach(thread.data!, id: \.id) { tweet in
            Text(formattedTweet(tweet)).fixedSize(horizontal: false, vertical: true).padding(5)
            TweetImages(media: thread.media(tweet: tweet))

            if let reference = tweet.referenceURL(type: .quoted) {
              TweetEmbed(reference: reference)
            }
            
            if let poll = thread.poll(tweet: tweet) {
              TweetPoll(poll: poll)
            }
          }
        }.padding()
      }
    }
}

extension ConversationView {
  func formattedTweet(_ tweet: Tweet) -> String {
    var text = tweet.text
    tweet.entities?.urls?.forEach {
      text = text.replacingOccurrences(of: $0.url, with: "")
    }
    
    return text
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  var user: User {
    return thread.user(of: thread.conversationHead!)!
  }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
      ConversationView(thread: MockData.searchResponse)
    }
}
