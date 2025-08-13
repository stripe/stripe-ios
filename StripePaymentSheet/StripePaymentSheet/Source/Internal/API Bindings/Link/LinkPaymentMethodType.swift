//
//  LinkPaymentMethodType.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/12/25.
//

import Foundation

@_spi(STP) public enum LinkPaymentMethodType: String, CaseIterable {
    case card = "CARD"
    case bankAccount = "BANK_ACCOUNT"
}

extension Array where Element == LinkPaymentMethodType {
    var detailsTypes: Set<ConsumerPaymentDetails.DetailsType> {
        Set(map(\.detailsType))
    }
}

private extension LinkPaymentMethodType {
    var detailsType: ConsumerPaymentDetails.DetailsType {
        switch self {
        case .card:
            return .card
        case .bankAccount:
            return .bankAccount
        }
    }
}
