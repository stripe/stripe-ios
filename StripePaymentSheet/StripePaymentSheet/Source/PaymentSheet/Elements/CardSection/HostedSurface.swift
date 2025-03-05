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
        case .paymentSheet:
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
        case (.updateCardBrand, .paymentSheet):
            return .paymentSheetUpdateCard
        case (.updateCardBrandFailed, .paymentSheet):
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
        case (.updateCardBrand, .customerSheet):
            return .customerSheetUpdateCard
        case (.updateCardBrandFailed, .customerSheet):
            return .customerSheetUpdateCardFailed
        case (.closeEditScreen, .customerSheet):
            return .customerSheetClosesEditScreen
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
        case updateCardBrand
        case updateCardBrandFailed
        case setDefaultPaymentMethod
        case setDefaultPaymentMethodFailed
        case closeEditScreen
    }
}
