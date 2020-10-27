//
//  TweetEmbed.swift
//  ConversationSample
//
//  Created by Daniele Bernardi on 10/24/20.
//

import SwiftUI
import WebKit

struct TweetEmbed: View {
  let reference: URL
   
  var body: some View {
    WebView(url: reference)
  }
}

struct TweetEmbed_Previews: PreviewProvider {
    static var previews: some View {
      TweetEmbed(reference: URL(string: "https://twitter.com/jack/status/20")!)
    }
}

struct WebView: UIViewRepresentable {
  let url: URL
  
  var template: String = #"""
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
      <meta name="twitter:widgets:theme" content="light">
      <meta name="twitter:widgets:cards" content="hidden">
      <meta name="twitter:widgets:align" content="center">
      <meta name="twitter:widgets:dnt" content="true">
      <meta name="twitter:widgets:conversation" content="none">
    </head>
    <body style="background:transparent"><blockquote class="twitter-tweet" data-conversation="none"><a href="{{URL}}"></a></blockquote><script id="twitter-wjs" type="text/javascript" async defer src="https://platform.twitter.com/widgets.js"></script></body>
  </html>
  """#
   
  func makeUIView(context: Context) -> WKWebView {
    return WKWebView()
  }
   
  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(template.replacingOccurrences(of: "{{URL}}", with: url.absoluteString), baseURL: nil)
  }
}
