//
//  CardBrandFilter.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/18/24.
//

import Foundation
@_spi(STP) import StripeCore

struct CardBrandFilter {
    private let cardBrandAcceptance: PaymentSheet.CardBrandAcceptance
    
    /// Determines if a merchant can accept a card brand based on `cardBrandAcceptance`
    /// - Parameter cardBrand: The `STPCardBrand` to determine if acceptance
    /// - Returns: Returns true if this merchant can accept this card brand, false otherwise
    func isAccepted(cardBrand: STPCardBrand) -> Bool {
        switch cardBrandAcceptance {
        case .all:
            return true
        case .allowed(let allowedCardBrands):
            if let brandCategory = cardBrand.asBrandCategory, !allowedCardBrands.contains(brandCategory) {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDisallowedCardBrand,
                                                                     params: ["brand": STPCardBrandUtilities.apiValue(from: cardBrand)])
                return false
            }
        case .disallowed(let disallowedBrands):
            if let brandCategory = cardBrand.asBrandCategory, disallowedBrands.contains(brandCategory) {
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDisallowedCardBrand,
                                                                     params: ["brand": STPCardBrandUtilities.apiValue(from: cardBrand)])
                return false
            }
        }
        
        return true
    }
}

extension STPCardBrand {
    var asBrandCategory: PaymentSheet.CardBrandAcceptance.BrandCategory? {
        switch self {
        case .visa:
            return .visa
        case .amex:
            return .amex
        case .mastercard:
            return .mastercard
        case .discover, .JCB, .dinersClub, .unionPay:
            return .discoverGlobalNetwork
        case .cartesBancaires, .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}
