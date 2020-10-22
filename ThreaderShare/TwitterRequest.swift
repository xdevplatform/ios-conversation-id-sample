//
//  TwitterRequest.swift
//  ThreaderShare
//
//  Created by Daniele Bernardi on 10/21/20.
//

import Foundation
struct TwitterSettings : Codable {
  var bearerToken: String
}

enum TwitterRequestError: Error {
  case missingBearerToken
  case requestFailed
  case conversationNotFound
  case tweetTooOld
  case tweetNotFound
  case unknown
}

class Twitter {

  static func getBearerToken() -> String? {
    if let settingsPath = Bundle.main.path(forResource: "TwitterSettings", ofType: "plist"),
          let xml = FileManager.default.contents(atPath: settingsPath),
          let plist = try? PropertyListDecoder().decode(TwitterSettings.self, from: xml) {
      return plist.bearerToken
    }
    
    return nil
  }
  
  static func decode<T: Decodable>(_ json: Data) throws -> T {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.000Z"
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(formatter)
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return try decoder.decode(T.self, from: json)
  }
  
  static func request(url: URL, cached: Bool = true) -> Result<TweetLookupResponse?, TwitterRequestError> {
    var result: Result<TweetLookupResponse?, TwitterRequestError>!
    
    guard let bearerToken = Twitter.getBearerToken(),
          !bearerToken.isEmpty else {
      return .failure(.missingBearerToken)
    }
        
    if cached,
       let data = FileCache.read(url),
       let body: TweetLookupResponse = try? Twitter.decode(data) {
      result = .success(body)
      return result
    }

    let semaphore = DispatchSemaphore(value: 0)
    var request = URLRequest(url: url)
    request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request) { (data, _, _) in
      if let data = data,
         let body: TweetLookupResponse = try? Twitter.decode(data) {
        if cached {
          FileCache.write(url, data: data)
        }

        result = .success(body)
      } else {
        result = .failure(.requestFailed)
      }
      
      semaphore.signal()
    }.resume()
    
    _ = semaphore.wait(wallTimeout: .distantFuture)
    return result
  }
}
