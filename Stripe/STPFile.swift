//
//  STPFile.swift
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// The purpose of the uploaded file.
/// - seealso: https://stripe.com/docs/file-upload
@objc
public enum STPFilePurpose: Int {
  /// Identity document file
  case identityDocument
  /// Dispute evidence file
  case disputeEvidence
  /// A file of unknown purpose type
  case unknown
}

/// Representation of a file upload object in the Stripe API.
/// - seealso: https://stripe.com/docs/api#file_uploads
public class STPFile: NSObject, STPAPIResponseDecodable {
  /// The token for this file.
  @objc public private(set) var fileId: String?
  /// The date this file was created.
  @objc public private(set) var created: Date?
  /// The purpose of this file. This can be either an identifing document or an evidence dispute.
  /// - seealso: https://stripe.com/docs/file-upload
  @objc public private(set) var purpose: STPFilePurpose = .unknown
  /// The file size in bytes.
  @objc public private(set) var size: NSNumber?
  /// The file type. This can be "jpg", "png", or "pdf".
  @objc public private(set) var type: String?

  /// Returns the string value for a purpose.
  @objc(stringFromPurpose:)
  public class func string(from purpose: STPFilePurpose) -> String? {
    return
      (self.stringToPurposeMapping() as NSDictionary).allKeys(
        for: NSNumber(value: purpose.rawValue)
      ).first as? String
  }
  @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

  required internal override init() {
    super.init()
  }

  // See STPFile+Private.h

  // MARK: - STPFilePurpose
  class func stringToPurposeMapping() -> [String: NSNumber] {
    return [
      "dispute_evidence": NSNumber(value: STPFilePurpose.disputeEvidence.rawValue),
      "identity_document": NSNumber(value: STPFilePurpose.identityDocument.rawValue),
    ]
  }

  @objc(purposeFromString:)
  class func purpose(from string: String) -> STPFilePurpose {
    let key = string.lowercased()
    let purposeNumber = self.stringToPurposeMapping()[key]

    if let purposeNumber = purposeNumber {
      return (STPFilePurpose(rawValue: purposeNumber.intValue))!
    }

    return .unknown
  }

  // MARK: - Equality
  /// :nodoc:
  @objc
  public override func isEqual(_ object: Any?) -> Bool {
    return isEqual(to: object as? STPFile)
  }

  func isEqual(to file: STPFile?) -> Bool {
    if self === file {
      return true
    }
    guard let file = file else {
      return false
    }
    return fileId == file.fileId
  }

  /// :nodoc:
  @objc public override var hash: Int {
    return fileId?.hash ?? 0
  }

  // MARK: - STPAPIResponseDecodable
  @objc
  public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    // required fields
    let stripeId = dict.stp_string(forKey: "id")
    let created = dict.stp_date(forKey: "created")
    let size = dict.stp_number(forKey: "size")
    let type = dict.stp_string(forKey: "type")
    let rawPurpose = dict.stp_string(forKey: "purpose")
    if stripeId == nil || created == nil || size == nil || type == nil || rawPurpose == nil {
      return nil
    }

    let file = self.init()
    file.fileId = stripeId
    file.created = created
    file.size = size
    file.type = type

    file.purpose = self.purpose(from: rawPurpose ?? "")
    file.allResponseFields = response

    return file
  }
}
