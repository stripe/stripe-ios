//
//  HostedSurface.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 12/20/23.
//

import Foundation
@_spi(STP) import StripeCore

// Used to indicate if this card section is being used by either PaymentSheet or CustomerSheet
@_spi(STP) public enum HostedSurface {
    case paymentSheet
    case customerSheet

    init(config: PaymentSheetFormFactoryConfig) {
        switch config {
        case .paymentElement:
            self = .paymentSheet
        case .customerSheet:
            self = .customerSheet
        }
    }

    func analyticEvent(for event: CardUpdateEvents) -> STPAnalyticEvent {
        switch (event, self) {
        case (.displayCardBrandDropdownIndicator, .paymentSheet):
            return .paymentSheetDisplayCardBrandDropdownIndicator
        case (.cardBrandSelected, .paymentSheet):
            return .paymentSheetCardBrandSelected
        case (.openEditScreen, .paymentSheet):
            return .paymentSheetOpenEditScreen
        case (.updateCard, .paymentSheet):
            return .paymentSheetUpdateCard
        case (.updateCardFailed, .paymentSheet):
            return .paymentSheetUpdateCardFailed
        case (.setDefaultPaymentMethod, .paymentSheet):
            return .paymentSheetSetDefaultPaymentMethod
        case (.setDefaultPaymentMethodFailed, .paymentSheet):
            return .paymentSheetSetDefaultPaymentMethodFailed
        case (.closeEditScreen, .paymentSheet):
            return .paymentSheetClosesEditScreen
        case (.displayCardBrandDropdownIndicator, .customerSheet):
            return .customerSheetDisplayCardBrandDropdownIndicator
        case (.cardBrandSelected, .customerSheet):
            return .customerSheetCardBrandSelected
        case (.openEditScreen, .customerSheet):
            return .customerSheetOpenEditScreen
        case (.updateCard, .customerSheet):
            return .customerSheetUpdateCard
        case (.updateCardFailed, .customerSheet):
            return .customerSheetUpdateCardFailed
        case (.closeEditScreen, .customerSheet):
            return .customerSheetClosesEditScreen
        // These events never actually happen— this data is sent in CustomerSheet on its confirm call
        case (.setDefaultPaymentMethod, .customerSheet):
            return STPAnalyticEvent.unexpectedCustomerSheetError
        case (.setDefaultPaymentMethodFailed, .customerSheet):
            return STPAnalyticEvent.unexpectedCustomerSheetError
        }
    }

    // Helper for mapping between PaymentSheet and CustomerSheet CBC events
    enum CardUpdateEvents {
        case displayCardBrandDropdownIndicator
        case cardBrandSelected
        case openEditScreen
        case updateCard
        case updateCardFailed
        case setDefaultPaymentMethod
        case setDefaultPaymentMethodFailed
        case closeEditScreen
    }
}
