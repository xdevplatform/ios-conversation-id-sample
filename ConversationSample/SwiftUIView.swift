//
//  SwiftUIView.swift
//  Threader
//
//  Created by Daniele Bernardi on 10/23/20.
//

import SwiftUI
import URLImage

struct ConversationView: View {
  var thread: TweetLookupResponse
    var body: some View {
      ScrollView() {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(thread.data!, id: \.id) { tweet in
            Text(formattedTweet(tweet)).fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            ForEach(thread.media(tweet: tweet) ?? [], id: \.mediaKey) {
              media in
              URLImage(url: URL(string: (media.type == .photo ? media.url! : media.previewImageUrl)!)!) {
                $0.resizable().aspectRatio(contentMode: .fit)
              }
            }
            
            if let reference = tweet.referenceURL(type: .quoted) {
              TweetEmbed(reference: reference)
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
