//
//  TweetPoll.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/26/20.
//

import SwiftUI

struct TweetPoll: View {
  var poll: Poll
    var body: some View {
      VStack {
        ForEach(poll.options, id: \.position) { option in
          TweetPollOption(position: option.position, poll: poll)
        }
      }
    }
}

struct TweetPoll_Previews: PreviewProvider {
    static var previews: some View {
      TweetPoll(poll: MockData.poll)
    }
}
