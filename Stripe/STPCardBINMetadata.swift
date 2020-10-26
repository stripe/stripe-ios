//
//  STPCardBINMetadata.swift
//  Stripe
//
//  Created by Cameron Sabol on 7/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

class STPCardBINMetadata: NSObject, STPAPIResponseDecodable {
  let ranges: [STPBINRange]
  let allResponseFields: [AnyHashable: Any]

  private init(ranges: [STPBINRange], allResponseFields: [AnyHashable: Any]) {

    self.ranges = ranges
    self.allResponseFields = allResponseFields
    super.init()
  }

  // #warning("Remove when STPAPIRequest doesn't need an instance of this for deserialization")
  convenience override init() {
    self.init(ranges: [], allResponseFields: [:])
  }

  static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let dict = response else {
      return nil
    }

    var ranges: [STPBINRange] = []
    if let dataArray = dict["data"] as? [[AnyHashable: Any]] {
      for rangeDict in dataArray {
        if let binRange = STPBINRange.decodedObject(fromAPIResponse: rangeDict) {
          ranges.append(binRange)
        }
      }
    }

    guard ranges.count > 0 else {
      return nil
    }

    return STPCardBINMetadata(ranges: ranges, allResponseFields: dict) as? Self
  }

}
