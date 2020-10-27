//
//  TweetImages.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/26/20.
//

import SwiftUI

struct TweetImages: View {
  var media: [Media]?

  @ViewBuilder
  var body: some View {
    if let media = media {
      VStack {
        ForEach(media, id: \.mediaKey) { image in
          TweetImage(media: image)
        }
      }
    }
  }
}

struct TweetImages_Previews: PreviewProvider {
    static var previews: some View {
      TweetImages(media: [MockData.media, MockData.media, MockData.media])
    }
}
