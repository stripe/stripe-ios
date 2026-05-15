//
//  LinkPaymentMethodType.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/12/25.
//

import Foundation

@_spi(STP) import StripeCore

/// The payment method types supported by the Link flow.
@_spi(STP) @_spi(LinkControllerPreview) public enum LinkPaymentMethodType: String, CaseIterable {
    case card = "CARD"
    case bankAccount = "BANK_ACCOUNT"
}

extension Array where Element == LinkPaymentMethodType {
    var detailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>> {
        Set(map(\.detailsType))
    }
}

private extension LinkPaymentMethodType {
    var detailsType: ParsedEnum<ConsumerPaymentDetails.DetailsType> {
        switch self {
        case .card:
            return ParsedEnum(.card)
        case .bankAccount:
            return ParsedEnum(.bankAccount)
        }
    }
}
