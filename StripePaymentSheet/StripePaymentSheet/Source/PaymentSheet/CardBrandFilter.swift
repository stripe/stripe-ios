//
//  CardBrandFilter.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/10/24.
//

import Foundation

struct CardBrandFilter: Equatable {

    static let `default`: CardBrandFilter = .init(cardBrandAcceptance: .all)

    private let cardBrandAcceptance: PaymentSheet.CardBrandAcceptance

    init(cardBrandAcceptance: PaymentSheet.CardBrandAcceptance) {
        self.cardBrandAcceptance = cardBrandAcceptance
    }

    /// Determines if a merchant can accept a card brand based on `cardBrandAcceptance`
    /// - Parameter cardBrand: The `STPCardBrand` to determine if acceptance
    /// - Returns: Returns true if this merchant can accept this card brand, false otherwise
    func isAccepted(cardBrand: STPCardBrand) -> Bool {
        switch cardBrandAcceptance {
        case .all:
            return true
        case .allowed(let allowedCardBrands):
            // If a merchant has specified a list of brands to allow, block unknown brands
            guard let brandCategory = cardBrand.asBrandCategory else {
                return false
            }

            if !allowedCardBrands.contains(brandCategory) {
                return false
            }
        case .disallowed(let disallowedBrands):
            if let brandCategory = cardBrand.asBrandCategory, disallowedBrands.contains(brandCategory) {
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
            return .discover
        case .cartesBancaires, .unknown:
            return nil
        @unknown default:
            return nil
        }
    }
}

extension PaymentElementConfiguration {
    var cardBrandFilter: CardBrandFilter {
        .init(cardBrandAcceptance: cardBrandAcceptance)
    }
}

extension CustomerSheet.Configuration {
    var cardBrandFilter: CardBrandFilter {
        .init(cardBrandAcceptance: cardBrandAcceptance)
    }
}
