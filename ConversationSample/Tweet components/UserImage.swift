//
//  UserImage.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/27/20.
//

import SwiftUI

struct UserImage: View {
  var user: User
  
  @ViewBuilder
  var body: some View {
    if let url = URL(string: user.profileImageUrl),
      let imageData = try? Data(contentsOf: url),
       let image = UIImage(data: imageData) {
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 64, height: 64, alignment: .center).clipShape(Circle())
    }
  }}

struct UserImage_Previews: PreviewProvider {
  static var previews: some View {
    UserImage(user: MockData.user)
  }
}
