//
//  STPMultipartFormDataEncoder.swift
//  Stripe
//
//  Created by Charles Scalesse on 12/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// Encoder class to generate the HTTP body data for a multipart/form-data request.
/// - seealso: https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4
class STPMultipartFormDataEncoder: NSObject {
  /// Generates the HTTP body data from an array of parts.
  class func multipartFormData(for parts: [STPMultipartFormDataPart], boundary: String) -> Data {
    var data = Data()
    let boundaryData = "--\(boundary)\r\n".data(using: .utf8)

    for part in parts {
      if let boundaryData = boundaryData {
        data.append(boundaryData)
      }
      data.append(part.composedData())
    }

    if let data1 = "--\(boundary)--\r\n".data(using: .utf8) {
      data.append(data1)
    }

    return data
  }

  /// Generates a unique boundary string to be used between parts.
  class func generateBoundary() -> String {
    return "Stripe-iOS-\(UUID().uuidString)"
  }
}
