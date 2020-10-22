//
//  FileCache.swift
//  ThreaderShare
//
//  Created by Daniele Bernardi on 10/21/20.
//

import Foundation
import CryptoKit

class FileCache {
  static func write(_ url: URL, data: Data) -> Void {
    if let fileManager = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
      let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
      let cacheFile = fileManager.appendingPathComponent("\(hash).json")
      try? data.write(to: cacheFile, options: .atomicWrite)
    }
  }
  
  static func read(_ url: URL) -> Data? {
    let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
    
    if let fileManager = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
       let cachedResponse = try? Data(contentsOf: fileManager.appendingPathComponent("\(hash).json")) {
      return cachedResponse
    }
    
    return nil
  }
}
