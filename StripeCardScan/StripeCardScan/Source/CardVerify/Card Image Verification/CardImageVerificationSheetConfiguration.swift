//
//  CardImageVerificationSheetConfiguration.swift
//  StripeCardScan
//
//  Created by Jaime Park on 3/11/22.
//

import Foundation
import UIKit

// MARK: - Configuration
extension CardImageVerificationSheet {
    public struct Configuration {
        /// The API client instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// The amount of frames that must have a centered, focused card before the
        /// scan is allowed to terminate. This is an `experimental` feature that should
        /// only be used with guidance from Stripe support.
        @_spi(STP) public var strictModeFrames: StrictModeFrameCount = .none

        public init() {}
    }

    /// Enum describing the amount of frames that must have a centered, focused card before the
    /// scan is allowed to terminate. This is an `experimental` feature that should
    /// only be used with guidance from Stripe support.
    @_spi(STP) public enum StrictModeFrameCount: Int, Equatable {
        case `none`
        case low
        case medium
        case high

        internal var totalFrameCount: Int {
            switch self {
            case .none: return 0
            case .low: return 1
            case .medium: return CardVerifyFraudData.maxCompletionLoopFrames / 2
            case .high: return CardVerifyFraudData.maxCompletionLoopFrames
            }
        }
    }
}
