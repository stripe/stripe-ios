//
//  NSURLComponents+Stripe.swift
//  Stripe
//
//  Created by Brian Dorfman on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

extension NSURLComponents {
  /// Returns or sets self.queryItems as a dictionary where all the keys are the item
  /// names and the values are the values. When reading, if there are duplicate
  /// names, earlier ones are overwritten by later ones.
  @objc var stp_queryItemsDictionary: [String: String] {
    get {
      guard let queryItems = queryItems else {
        return [:]
      }
      var queryItemsDict = [String: String]()
      for queryItem in queryItems {
        queryItemsDict[queryItem.name] = queryItem.value
      }
      return queryItemsDict
    }
    set(stp_queryItemsDictionary) {
      var queryItems: [URLQueryItem] = []
      for (key, value) in stp_queryItemsDictionary {
        queryItems.append(URLQueryItem(name: key, value: value))
      }

      self.queryItems = queryItems
    }
  }

  /// Returns YES if the passed in url matches self in scheme, host, and path,
  /// AND all the query items in self are also in the passed
  /// in components (as determined by `stp_queryItemsDictionary`)
  /// This is used for URL routing style matching
  /// - Parameter rhsComponents: The components to match against
  /// - Returns: YES if there is a match, NO otherwise.
  func stp_matchesURLComponents(_ rhsComponents: NSURLComponents) -> Bool {
    var matches =
      (scheme?.lowercased() == rhsComponents.scheme?.lowercased())
      && (host?.lowercased() == rhsComponents.host?.lowercased()) && (path == rhsComponents.path)

    if matches {
      let rhsQueryItems = rhsComponents.stp_queryItemsDictionary

      for queryItem in queryItems ?? [] {
        if !(rhsQueryItems[queryItem.name] == queryItem.value) {
          matches = false
          break
        }
      }
    }

    return matches
  }
}
