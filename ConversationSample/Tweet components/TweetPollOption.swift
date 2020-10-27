//
//  PollOption.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/26/20.
//

import SwiftUI

struct TweetPollOption: View {
  var position: Int
  var poll: Poll
  
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
        Rectangle()
          .cornerRadius(3.0)
          .frame(width: geometry.size.width * CGFloat(poll.percentValue(position: position)), height: 50)
          .foregroundColor(poll.isLeading(position: position) ? .blue : .gray)
        HStack {
          Text(poll.option(position: position)!.label)
            .fontWeight(poll.isLeading(position: position) ? .bold : .regular)
            .frame(height: 50, alignment: .trailing)
          Spacer()
          Text(poll.percentLabel(position: position)).fontWeight(poll.isLeading(position: position) ? .bold : .regular)
        }
      }
    }.frame(maxHeight: 50)
  }
}

struct TweetPollOption_Previews: PreviewProvider {
  static var previews: some View {
    TweetPollOption(position: 1, poll: MockData.poll)
      .previewLayout(.fixed(width: 375, height: 50))
  }
}
