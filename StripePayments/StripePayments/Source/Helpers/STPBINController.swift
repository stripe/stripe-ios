//
//  STPBINController.swift
//  StripePayments
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public struct STPBINRange: Decodable, Equatable {
    @_spi(STP) public let panLength: UInt
    @_spi(STP) public let brand: STPCardBrand
    @_spi(STP) public let accountRangeLow: String
    @_spi(STP) public let accountRangeHigh: String
    @_spi(STP) public let country: String?

    private enum CodingKeys: String, CodingKey {
        case panLength = "pan_length"
        case brand = "brand"
        case accountRangeLow = "account_range_low"
        case accountRangeHigh = "account_range_high"
        case country = "country"
    }

    @_spi(STP) public init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.panLength = try container.decode(UInt.self, forKey: .panLength)
        let brandString = try container.decode(String.self, forKey: .brand)
        self.brand = STPCard.brand(from: brandString)
        self.accountRangeLow = try container.decode(String.self, forKey: .accountRangeLow)
        self.accountRangeHigh = try container.decode(String.self, forKey: .accountRangeHigh)
        self.country = try? container.decode(String.self, forKey: .country)
        self.isHardcoded = false
    }

    @_spi(STP) public init(
        panLength: UInt,
        brand: STPCardBrand,
        accountRangeLow: String,
        accountRangeHigh: String,
        country: String?
    ) {
        self.panLength = panLength
        self.brand = brand
        self.accountRangeLow = accountRangeLow
        self.accountRangeHigh = accountRangeHigh
        self.country = country
        self.isHardcoded = true
    }

    /// indicates bin range was included in the SDK (rather than downloaded from edge service)
    @_spi(STP) public var isHardcoded: Bool
}

extension STPBINRange {
    /// Number matching strategy: Truncate the longer of the two numbers (theirs and our
    /// bounds) to match the length of the shorter one, then do numerical compare.
    func matchesNumber(_ number: String) -> Bool {

        var withinLowRange = false
        var withinHighRange = false

        if number.count < (accountRangeLow.count) {
            withinLowRange =
                Int(number) ?? 0 >= Int(
                    (accountRangeLow as NSString?)?.substring(to: number.count) ?? ""
                )
                ?? 0
        } else {
            withinLowRange =
                Int((number as NSString).substring(to: accountRangeLow.count)) ?? 0 >= Int(
                    accountRangeLow
                )
                ?? 0
        }

        if number.count < (accountRangeHigh.count) {
            withinHighRange =
                Int(number) ?? 0 <= Int(
                    (accountRangeHigh as NSString?)?.substring(to: number.count) ?? ""
                ) ?? 0
        } else {
            withinHighRange =
                Int((number as NSString).substring(to: accountRangeHigh.count)) ?? 0 <= Int(
                    accountRangeHigh
                ) ?? 0
        }

        return withinLowRange && withinHighRange
    }

    func compare(_ other: STPBINRange) -> ComparisonResult {
        let result = NSNumber(value: accountRangeLow.count).compare(
            NSNumber(value: other.accountRangeLow.count)
        )

        // If they are the same range unknown brands go first.
        if result == .orderedSame {
            if brand == .unknown && other.brand != .unknown {
                return .orderedAscending
            } else if brand != .unknown && other.brand == .unknown {
                return .orderedDescending
            }
        }

        return result

    }
}

private let CardMetadataURL = URL(string: "https://api.stripe.com/edge-internal/card-metadata")!

extension STPBINRange {
    struct STPBINRangeResponse: Decodable {
        var data: [STPBINRange]
    }

    typealias BINRangeCompletionBlock = (Result<STPBINRangeResponse, Error>) -> Void

    /// Converts a PKPayment object into a Stripe token using the Stripe API.
    /// - Parameters:
    ///   - payment:     The user's encrypted payment information as returned from a PKPaymentAuthorizationController. Cannot be nil.
    ///   - completion:  The callback to run with the returned Stripe token (and any errors that may have occurred).
    static func retrieve(
        apiClient: STPAPIClient = .shared,
        forPrefix binPrefix: String,
        completion: @escaping BINRangeCompletionBlock
    ) {
        assert(binPrefix.count == 6, "Requests can only be made with 6-digit binPrefixes.")
        // not adding explicit handling for above assert as endpoint will error anyway
        let params = [
            "bin_prefix": binPrefix
        ]

        apiClient.get(url: CardMetadataURL, parameters: params, completion: completion)
    }
}

@_spi(STP) public typealias STPRetrieveBINRangesCompletionBlock = (Result<[STPBINRange], Error>) ->
    Void

@_spi(STP) public class STPBINController {
    @_spi(STP) public static let shared = STPBINController()

    /// For testing
    @_spi(STP) public func reset() {
        _performSync {
            sAllRanges = STPBINController.STPBINRangeInitialRanges
        }
    }

    @_spi(STP) public func isLoadingCardMetadata(forPrefix binPrefix: String) -> Bool {
        var isLoading = false
        self._retrievalQueue.sync(execute: {
            let binPrefixKey = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest)
            isLoading = sPendingRequests[binPrefixKey] != nil
        })
        return isLoading
    }

    @_spi(STP) public func allRanges() -> [STPBINRange] {
        var ret: [STPBINRange]?
        self._performSync(withAllRangesLock: {
            ret = sAllRanges
        })
        return ret ?? []
    }

    @_spi(STP) public func binRanges(forNumber number: String) -> [STPBINRange] {
        return self.allRanges().filter { (binRange) -> Bool in
            binRange.matchesNumber(number)
        }
    }

    @_spi(STP) public func binRanges(for brand: STPCardBrand) -> [STPBINRange] {
        return self.allRanges().filter { (binRange) -> Bool in
            binRange.brand == brand
        }
    }

    @_spi(STP) public func mostSpecificBINRange(forNumber number: String) -> STPBINRange {
        let validRanges = self.allRanges().filter { (range) -> Bool in
            range.matchesNumber(number)
        }
        return validRanges.sorted { (r1, r2) -> Bool in
            if number.isEmpty {
                // empty numbers should always best match to unknown brand
                if r1.brand == .unknown && r2.brand != .unknown {
                    return true
                } else if r1.brand != .unknown && r2.brand == .unknown {
                    return false
                }
            }
            return r1.compare(r2) == .orderedAscending
        }.last!
    }

    @_spi(STP) public func maxCardNumberLength() -> Int {
        return kMaxCardNumberLength
    }

    /// Returns the shortest possible card number length for the brand
    @_spi(STP) public func minCardNumberLength(for brand: STPCardBrand) -> Int {
        switch brand {
        case .visa, .amex, .mastercard, .discover, .JCB, .dinersClub, .cartesBancaires:
            return allRanges().reduce(Int.max) { currentMinimum, range in
                if range.brand == brand {
                    return min(currentMinimum, Int(range.panLength))
                } else {
                    return currentMinimum
                }
            }
        case .unionPay:
            return 16
        case .unknown:
            return 13
        }
    }

    @_spi(STP) public func minLengthForFullBINRange() -> Int {
        return kPrefixLengthForMetadataRequest
    }

    /// This is basically a wrapper around:
    ///
    /// 1. Does BIN have variable length pans, i.e. do we need to call the metadata service
    /// 2. If yes, have we already gotten a response from the metadata service
    @_spi(STP) public func hasBINRanges(forPrefix binPrefix: String) -> Bool {
        if self.isInvalidBINPrefix(binPrefix) {
            return true  // we won't fetch any more info for this prefix
        }
        // if we know a card has a static length, we don't need to ask the BIN service
        if !self.isVariableLengthBINPrefix(binPrefix) {
            return true
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

    func isInvalidBINPrefix(_ binPrefix: String) -> Bool {
        let firstFive = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest - 1)
        return (self.mostSpecificBINRange(forNumber: firstFive)).brand == .unknown
    }

    /// This will asynchronously check if we have already fetched metadata for this prefix and if we have not will
    /// issue a network request to retrieve it if possible.
    /// - Parameter recordErrorsAsSuccess: An unfortunate toggle for behavior that STPCardFormView/STPPaymentCardTextField depends on. See https://jira.corp.stripe.com/browse/MOBILESDK-724
    /// - Parameter onlyFetchForVariableLengthBINs: Only hit the network if a BIN is known to be variable length. (e.g. UnionPay).
    /// If this is disabled, we will *always* fetch and cache BIN information for the passed BIN.
    /// Use caution when disabling this: The BIN length information coming from the service may not be correct, which will
    /// cause issues when validating PAN length.
    @_spi(STP) public func retrieveBINRanges(
        forPrefix binPrefix: String,
        recordErrorsAsSuccess: Bool = true,
        onlyFetchForVariableLengthBINs: Bool = true,
        completion: @escaping STPRetrieveBINRangesCompletionBlock
    ) {
        self._retrievalQueue.async(execute: {
            let binPrefixKey = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest)
            if self.sRetrievedRanges[binPrefixKey] != nil
                || (binPrefixKey.count) < kPrefixLengthForMetadataRequest
                || self.isInvalidBINPrefix(binPrefixKey)
                || (onlyFetchForVariableLengthBINs && !self.isVariableLengthBINPrefix(binPrefix))
            {
                // if we already have a metadata response or the binPrefix isn't long enough to make a request,
                // or we know that this is not a valid BIN prefix
                // or we know this isn't a BIN prefix that could contain variable length BINs
                // return the bin ranges we already have on device
                DispatchQueue.main.async(execute: {
                    completion(.success(self.binRanges(forNumber: binPrefix)))
                })
            } else if self.sPendingRequests[binPrefixKey] != nil {
                // A request for this prefix is already in flight, add the completion block to sPendingRequests
                if let sPendingRequest = self.sPendingRequests[binPrefixKey] {
                    self.sPendingRequests[binPrefixKey] = sPendingRequest + [completion]
                }
            } else {

                self.sPendingRequests[binPrefixKey] = [completion]

                STPBINRange.retrieve(
                    forPrefix: binPrefixKey,
                    completion: { result in
                        self._retrievalQueue.async(execute: {
                            let ranges = result.map { $0.data }
                            let completionBlocks = self.sPendingRequests[binPrefixKey]

                            self.sPendingRequests.removeValue(forKey: binPrefixKey)

                            if recordErrorsAsSuccess {
                                // The following is a comment for STPCardFormView/STPPaymentCardTextField:
                                // we'll record this response even if there was an error
                                // this will prevent our validation from getting stuck thinking we don't
                                // have enough info if the metadata service is down or unreachable
                                // Could improve this in the future with "smart" retries
                                self.sRetrievedRanges[binPrefixKey] = (try? ranges.get()) ?? []
                            } else if let ranges = try? ranges.get(), !ranges.isEmpty {
                                self.sRetrievedRanges[binPrefixKey] = ranges
                            }
                            self._performSync(withAllRangesLock: {
                                self.sAllRanges =
                                    self.sAllRanges + ((try? ranges.get()) ?? [])
                            })

                            if case .failure = ranges {
                                STPAnalyticsClient.sharedClient.logCardMetadataResponseFailure()
                            }

                            DispatchQueue.main.async(execute: {
                                for block in completionBlocks ?? [] {
                                    block(ranges)
                                }
                            })
                        })
                    }
                )
            }
        })
    }

    // MARK: - Class Utilities

    static let STPBINRangeInitialRanges: [STPBINRange] = {
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
            ("67", "67", 16, .mastercard),  // Maestro
            // UnionPay
            ("62", "62", 16, .unionPay),
            ("81", "81", 16, .unionPay),
            // Include at least one known 19-digit BIN for maxLength
            ("621598", "621598", 19, .unionPay),
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
            let binRange = STPBINRange.init(
                panLength: range.2,
                brand: range.3,
                accountRangeLow: range.0,
                accountRangeHigh: range.1,
                country: nil
            )
            binRanges.append(binRange)
        }
        return binRanges
    }()

    var sAllRanges: [STPBINRange] = {
        return STPBINRangeInitialRanges
    }()

    let sAllRangesLockQueue: DispatchQueue = {
        DispatchQueue(label: "com.stripe.STPBINRange.allRanges")
    }()

    func _performSync(withAllRangesLock block: () -> Void) {
        sAllRangesLockQueue.sync(execute: {
            block()
        })
    }

    // sPendingRequests contains the completion blocks for a given metadata request that we have not yet gotten a response for
    var sPendingRequests: [String: [STPRetrieveBINRangesCompletionBlock]] = [:]

    // sRetrievedRanges tracks the bin prefixes for which we've already received metadata responses
    var sRetrievedRanges: [String: [STPBINRange]] = [:]

    // _retrievalQueue protects access to the two above dictionaries, sSpendingRequests and sRetrievedRanges
    let _retrievalQueue: DispatchQueue = {
        return DispatchQueue(label: "com.stripe.retrieveBINRangesForPrefix")
    }()

    func isVariableLengthBINPrefix(_ binPrefix: String) -> Bool {
        guard !binPrefix.isEmpty else {
            return false
        }
        let firstFive = binPrefix.stp_safeSubstring(to: kPrefixLengthForMetadataRequest - 1)
        // Only UnionPay has variable-length cards at the moment.
        return (self.mostSpecificBINRange(forNumber: firstFive)).brand == .unionPay
    }
}

private let kMaxCardNumberLength: Int = 19
private let kPrefixLengthForMetadataRequest: Int = 6
