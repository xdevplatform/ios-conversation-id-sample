//
//  ShareViewController.swift
//  threadshare
//
//  Created by Daniele Bernardi on 10/15/20.
//

import UIKit
import Social
import SwiftUI


@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    self.setViewControllers([ShareViewController()], animated: false)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

class ShareViewController: UIViewController {
    
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .systemGray6
    self.navigationItem.title = "Thread"
    
    let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    self.navigationItem.setRightBarButton(itemDone, animated: false)
    
    if let extensionContext = extensionContext,
       let item = extensionContext.inputItems.first as? NSExtensionItem,
       let itemProvider = item.attachments?.first {
      if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
        itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
          if let shareURL = url as? URL,
             self.validateTweetURL(url: shareURL) != nil {
            self.findThread(tweetURL: shareURL)
          } else {
            let alert = UIAlertController(title: "Invalid thread or URL", message: "This is not a valid Twitter thread, or the thread is older than seven days.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (UIAlertAction) in
              self.cancel()
            }))
            
            DispatchQueue.main.async {
              self.present(alert, animated: true)
            }
          }
        }
      }
    }
  }
  
  func validateTweetURL(url: URL) -> URL? {
    let pattern = #"(?:https:\/\/(?:.*\.)?twitter.com\/[\w\d_]+\/status\/)(\d{1,19})"#
    guard (url.absoluteString.range(of: pattern, options: .regularExpression) != nil) else {
      return nil
    }
    
    return url
  }
  
  func getId(tweetURL: URL) -> String {
    return tweetURL.pathComponents.last!
  }
  
  func alert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { (UIAlertAction) in
      self.cancel()
    }))
    DispatchQueue.main.async {
      self.present(alert, animated: true)
    }
  }
  
  func showError(for error: TwitterRequestError) -> Void {
    switch error {
    case .tweetNotFound:
      self.alert(title: "Tweet not found", message: "Could not get a valid Tweet.")

    case .conversationNotFound:
      self.alert(title: "Thread not found", message: "This Tweet does not belong to a thread, or the thread is older than seven days.")

    case .missingBearerToken:
      self.alert(title: "Missing Bearer token", message: "Your Bearer token is missing. Add your Bearer token in TwitterSettings.plist and build this project again.")

    case .tweetTooOld:
      self.alert(title: "Invalid tweet", message: "This is not a valid Twitter thread, or the thread is older than seven days.")
      
    case .requestFailed:
      self.alert(title: "Uh oh", message: "The network request feiled.")
      
    case .unknown:
      self.alert(title: "Technical difficulties", message: "Something wrong happened. Try again later.")
    }
  }
  
  func findThread(tweetURL: URL) {
    let tweetId = getId(tweetURL: tweetURL)
    
    let conversation = Conversation(of: tweetId)
    conversation.thread { (response, error) in
      if let error = error {
        self.showError(for: error)
        return
      }
      
      guard let response = response else {
        self.alert(title: "No thread", message: "Twitter did not return a thread. Try again later.")
        return
      }
      
      let threadView = ConversationView(thread: response)
      let hostingController = UIHostingController(rootView: threadView)
      hostingController.view.translatesAutoresizingMaskIntoConstraints = false
      self.addChild(hostingController)
      self.view.addSubview(hostingController.view)
      hostingController.didMove(toParent: self)

      NSLayoutConstraint.activate([
        hostingController.view.widthAnchor.constraint(equalTo: self.view.widthAnchor),
        hostingController.view.heightAnchor.constraint(equalTo: self.view.heightAnchor),
        hostingController.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
        hostingController.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
      ])
    }
  }
  
  @objc func cancel() {
    let error = NSError(domain: "some.bundle.identifier", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
    extensionContext?.cancelRequest(withError: error)
  }
  
  @objc func done() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
