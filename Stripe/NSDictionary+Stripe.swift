//
//  NSDictionary+Stripe.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

@objc
extension NSDictionary {
  func stp_dictionaryByRemovingNulls() -> [AnyHashable: Any] {
    var result = [AnyHashable: Any]()

    (self as NSDictionary).enumerateKeysAndObjects({ key, obj, _ in
      guard let key = key as? AnyHashable else {
        assertionFailure()
        return
      }
      if let obj = obj as? [Any] {
        // Save array after removing any null values
        let stp = obj.stp_arrayByRemovingNulls()
        result[key] = stp
      } else if let obj = obj as? NSDictionary {
        // Save dictionary after removing any null values
        let stp = obj.stp_dictionaryByRemovingNulls() as NSDictionary
        result[key] = stp
      } else if obj is NSNull {
        // Skip null value
      } else {
        // Save other value
        result[key] = obj
      }
    })

    // Make immutable copy
    return result
  }

  func stp_dictionaryByRemovingNonStrings() -> [String: String] {
    var result: [String: String] = [:]

    (self as NSDictionary).enumerateKeysAndObjects({ key, obj, _ in
      if let key = key as? String, let obj = obj as? String {
        // Save valid key/value pair
        result[key] = obj
      }
    })

    // Make immutable copy
    return result
  }

  // Getters
  func stp_array(forKey key: String) -> [Any]? {
    let value = self[key]
    if value != nil {
      return value as? [Any]
    }
    return nil
  }

  func stp_bool(forKey key: String, or defaultValue: Bool) -> Bool {
    let value = self[key]
    if value != nil {
      if let value = value as? NSNumber {
        return value.boolValue
      }
      if value is NSString {
        let string = (value as? String)?.lowercased()
        // boolValue on NSString is true for "Y", "y", "T", "t", or 1-9
        if (string == "true") || (string as NSString?)?.boolValue ?? false {
          return true
        } else {
          return false
        }
      }
    }
    return defaultValue
  }

  func stp_date(forKey key: String) -> Date? {
    let value = self[key]
    if let value = value as? NSNumber {
      let timeInterval = value.doubleValue
      return Date(timeIntervalSince1970: TimeInterval(timeInterval))
    } else if let value = value as? NSString {
      let timeInterval = value.doubleValue
      return Date(timeIntervalSince1970: TimeInterval(timeInterval))
    }
    return nil
  }

  func stp_dictionary(forKey key: String) -> [AnyHashable: Any]? {
    let value = self[key]
    if value != nil && (value is [AnyHashable: Any]) {
      return value as? [AnyHashable: Any]
    }
    return nil
  }

  func stp_int(forKey key: String, or defaultValue: Int) -> Int {
    let value = self[key]
    if let value = value as? NSNumber {
      return value.intValue
    } else if let value = value as? NSString {
      return Int(value.intValue)
    }
    return defaultValue
  }

  func stp_number(forKey key: String) -> NSNumber? {
    return self[key] as? NSNumber
  }

  func stp_string(forKey key: String) -> String? {
    let value = self[key]
    if value != nil && (value is NSString) {
      return value as? String
    }
    return nil
  }

  func stp_url(forKey key: String) -> URL? {
    let value = self[key]
    if value != nil && (value is NSString) && ((value as? String)?.count ?? 0) > 0 {
      return URL(string: value as? String ?? "")
    }
    return nil
  }
}
