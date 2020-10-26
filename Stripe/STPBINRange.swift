//
//  STPBINRange.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

typealias STPRetrieveBINRangesCompletionBlock = ([STPBINRange]?, Error?) -> Void
class STPBINRange: NSObject, STPAPIResponseDecodable {

  private(set) var allResponseFields: [AnyHashable: Any] = [:]

  private(set) var length: UInt = 0
  private(set) var brand: STPCardBrand = .unknown
  var qRangeLow: String?
  var qRangeHigh: String?
  private(set) var country: String?
  private(set) var isCardMetadata = false
  // indicates bin range was downloaded from edge service
  class func isLoadingCardMetadata(forPrefix binPrefix: String) -> Bool {
    var isLoading = false
    self._retrievalQueue.sync(execute: {
      let binPrefixKey = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest)
      isLoading = sPendingRequests[binPrefixKey] != nil
    })
    return isLoading
  }

  class func allRanges() -> [STPBINRange] {
    var ret: [STPBINRange]?
    self._performSync(withAllRangesLock: {
      ret = STPBINRangeAllRanges
    })

    return ret ?? []
  }

  class func binRanges(forNumber number: String) -> [STPBINRange] {
    return self.allRanges().filter { (binRange) -> Bool in
      binRange.matchesNumber(number)
    }
  }

  @objc(binRangesForBrand:) class func binRanges(for brand: STPCardBrand) -> [STPBINRange] {
    return self.allRanges().filter { (binRange) -> Bool in
      binRange.brand == brand
    }
  }

  class func mostSpecificBINRange(forNumber number: String) -> STPBINRange {
    let validRanges = self.allRanges().filter { (range) -> Bool in
      range.matchesNumber(number)
    }
    return validRanges.sorted { (r1, r2) -> Bool in
      r1.compare(r2) == .orderedAscending
    }.last!
  }

  class func maxCardNumberLength() -> Int {
    return kMaxCardNumberLength
  }

  class func minLengthForFullBINRange() -> Int {
    return kPrefixLengthForMetadataRequest
  }

  class func hasBINRanges(forPrefix binPrefix: String) -> Bool {
    if self.isInvalidBINPrefix(binPrefix) {
      return true  // we won't fetch any more info for this prefix
    }
    if !self.isVariableLengthBINPrefix(binPrefix) {
      return true  // if we know a card has a static length, we don't need to ask the BIN service
    }
    var hasBINRanges = false
    self._retrievalQueue.sync(execute: {
      let binPrefixKey = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest)
      hasBINRanges =
        (binPrefixKey.count) == kPrefixLengthForMetadataRequest
        && sRetrievedRanges[binPrefixKey] != nil
    })
    return hasBINRanges
  }

  class func isInvalidBINPrefix(_ binPrefix: String) -> Bool {
    let firstFive = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest - 1)
    return (self.mostSpecificBINRange(forNumber: firstFive)).brand == .unknown
  }

  // This will asynchronously check if we have already fetched metadata for this prefix and if we have not will
  // issue a network request to retrieve it if possible.
  class func retrieveBINRanges(
    forPrefix binPrefix: String, completion: @escaping STPRetrieveBINRangesCompletionBlock
  ) {

    self._retrievalQueue.async(execute: {
      let binPrefixKey = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest)
      if sRetrievedRanges[binPrefixKey] != nil
        || (binPrefixKey.count) < kPrefixLengthForMetadataRequest
        || self.isInvalidBINPrefix(binPrefixKey)
      {
        // if we already have a metadata response or the binPrefix isn't long enough to make a request,
        // or we know that this is not a valid BIN prefix
        // return the bin ranges we already have on device
        DispatchQueue.main.async(execute: {
          completion(self.binRanges(forNumber: binPrefix), nil)
        })
      } else if sPendingRequests[binPrefixKey] != nil {
        // A request for this prefix is already in flight, add the completion block to sPendingRequests
        if let sPendingRequest = sPendingRequests[binPrefixKey] {
          sPendingRequests[binPrefixKey] = sPendingRequest + [completion]
        }
      } else {

        sPendingRequests[binPrefixKey] = [completion]

        STPAPIClient.shared.retrieveCardBINMetadata(
          forPrefix: binPrefixKey,
          withCompletion: { cardMetadata, error in
            self._retrievalQueue.async(execute: {
              let ranges = cardMetadata?.ranges
              let completionBlocks = sPendingRequests[binPrefixKey]

              sPendingRequests.removeValue(forKey: binPrefixKey)
              if let ranges = ranges {
                sRetrievedRanges[binPrefixKey] = ranges
                self._performSync(withAllRangesLock: {
                  STPBINRange.STPBINRangeAllRanges = STPBINRangeAllRanges + ranges
                })
              } else {
                STPAnalyticsClient.sharedClient.logCardMetadataResponseFailure(
                  with: STPPaymentConfiguration.shared)
              }

              DispatchQueue.main.async(execute: {
                for block in completionBlocks ?? [] {
                  block(ranges, error)
                }
              })
            })
          })
      }
    })

  }

  /// Number matching strategy: Truncate the longer of the two numbers (theirs and our
  /// bounds) to match the length of the shorter one, then do numerical compare.
  func matchesNumber(_ number: String) -> Bool {

    var withinLowRange = false
    var withinHighRange = false

    if number.count < (qRangeLow?.count ?? 0) {
      withinLowRange =
        Int(number) ?? 0 >= Int((qRangeLow as NSString?)?.substring(to: number.count) ?? "") ?? 0
    } else {
      withinLowRange =
        Int((number as NSString).substring(to: qRangeLow?.count ?? 0)) ?? 0 >= Int(qRangeLow ?? "")
        ?? 0
    }

    if number.count < (qRangeHigh?.count ?? 0) {
      withinHighRange =
        Int(number) ?? 0 <= Int((qRangeHigh as NSString?)?.substring(to: number.count) ?? "") ?? 0
    } else {
      withinHighRange =
        Int((number as NSString).substring(to: qRangeHigh?.count ?? 0)) ?? 0 <= Int(
          qRangeHigh ?? "") ?? 0
    }

    return withinLowRange && withinHighRange
  }

  @objc func compare(_ other: STPBINRange) -> ComparisonResult {
    return NSNumber(value: qRangeLow?.count ?? 0).compare(
      NSNumber(value: other.qRangeLow?.count ?? 0))
  }

  // MARK: - STPAPIResponseDecodable
  required internal override init() {
    super.init()
  }

  class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
    let binRange = self.init()
    guard let response = response else {
      return nil
    }
    let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

    let qRangeLow = dict.stp_string(forKey: "account_range_low")
    let qRangeHigh = dict.stp_string(forKey: "account_range_high")
    let brandString = dict.stp_string(forKey: "brand")
    let length = dict.stp_number(forKey: "pan_length")
    if qRangeLow == nil || qRangeHigh == nil || brandString == nil || length == nil
      || STPCard.brand(from: brandString ?? "") == .unknown
    {
      return nil
    }

    binRange.qRangeLow = qRangeLow
    binRange.qRangeHigh = qRangeHigh
    binRange.brand = STPCard.brand(from: brandString ?? "")
    binRange.length = length?.uintValue ?? 0
    binRange.country = dict.stp_string(forKey: "country")
    binRange.isCardMetadata = true

    return binRange
  }

  // MARK: - Class Utilities

  static var STPBINRangeAllRanges: [STPBINRange] = {
    let ranges: [(String, String, UInt, STPCardBrand)] = [
      // Unknown
      ("", "", 19, .unknown),
      // American Express
      ("34", "34", 15, .amex),
      ("37", "37", 15, .amex),
      // Diners Club
      ("30", "30", 16, .dinersClub),
      ("36", "36", 14, .dinersClub),
      ("38", "39", 16, .dinersClub),
      // Discover
      ("60", "60", 16, .discover),
      ("64", "65", 16, .discover),
      // JCB
      ("35", "35", 16, .JCB),
      // Mastercard
      ("50", "59", 16, .mastercard),
      ("22", "27", 16, .mastercard),
      ("67", "67", 16, .mastercard) /* Maestro */,
      // UnionPay
      ("62", "62", 16, .unionPay),
      ("81", "81", 16, .unionPay),
      // Visa
      ("40", "49", 16, .visa),
      ("413600", "413600", 13, .visa),
      ("444509", "444509", 13, .visa),
      ("444509", "444509", 13, .visa),
      ("444550", "444550", 13, .visa),
      ("450603", "450603", 13, .visa),
      ("450617", "450617", 13, .visa),
      ("450628", "450629", 13, .visa),
      ("450636", "450636", 13, .visa),
      ("450640", "450641", 13, .visa),
      ("450662", "450662", 13, .visa),
      ("463100", "463100", 13, .visa),
      ("476142", "476142", 13, .visa),
      ("476143", "476143", 13, .visa),
      ("492901", "492902", 13, .visa),
      ("492920", "492920", 13, .visa),
      ("492923", "492923", 13, .visa),
      ("492928", "492930", 13, .visa),
      ("492937", "492937", 13, .visa),
      ("492939", "492939", 13, .visa),
      ("492960", "492960", 13, .visa),
    ]
    var binRanges: [STPBINRange] = []
    for range in ranges {
      let binRange = STPBINRange.init()
      binRange.qRangeLow = range.0
      binRange.qRangeHigh = range.1
      binRange.length = range.2
      binRange.brand = range.3
      binRanges.append(binRange)
    }
    return binRanges
  }()

  static let sAllRangesLockQueue: DispatchQueue = {
    DispatchQueue(label: "com.stripe.STPBINRange.allRanges")
  }()

  class func _performSync(withAllRangesLock block: () -> Void) {
    sAllRangesLockQueue.sync(execute: {
      block()
    })
  }

  // sPendingRequests contains the completion blocks for a given metadata request that we have not yet gotten a response for
  static var sPendingRequests: [String: [STPRetrieveBINRangesCompletionBlock]] = [:]

  // sRetrievedRanges tracks the bin prefixes for which we've already received metadata responses
  static var sRetrievedRanges: [String: [STPBINRange]] = [:]

  // _retrievalQueue protects access to the two above dictionaries, sSpendingRequests and sRetrievedRanges
  static let _retrievalQueue: DispatchQueue = {
    return DispatchQueue(label: "com.stripe.retrieveBINRangesForPrefix")
  }()

  class func isVariableLengthBINPrefix(_ binPrefix: String) -> Bool {
    let firstFive = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest - 1)
    // Only UnionPay has variable-length cards at the moment.
    return (self.mostSpecificBINRange(forNumber: firstFive)).brand == .unionPay
  }
}

private let kMaxCardNumberLength: Int = 19
private let kPrefixLengthForMetadataRequest: Int = 6
