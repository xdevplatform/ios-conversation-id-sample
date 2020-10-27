//
//  TweetImage.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/26/20.
//

import SwiftUI

struct TweetImage: View {
  let media: Media?
  @ViewBuilder
  var body: some View {
    if let media = media,
       let source = media.url ?? media.previewImageUrl,
       let url = URL(string: source),
      let imageData = try? Data(contentsOf: url),
       let image = UIImage(data: imageData) {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    }
  }
}

struct TweetImage_Previews: PreviewProvider {
    static var previews: some View {
      TweetImage(media: MockData.media)
    }
}
