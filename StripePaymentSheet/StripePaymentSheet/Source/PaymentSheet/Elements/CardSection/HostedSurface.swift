//
//  HostedSurface.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 12/20/23.
//

import Foundation
@_spi(STP) import StripeCore

// Used to indicate if this card section is being used by either PaymentSheet or CustomerSheet
enum HostedSurface {
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

    func analyticEvent(for event: CardBrandChoiceEvents) -> STPAnalyticEvent {
        switch (event, self) {
        case (.displayCardBrandDropdownIndicator, .paymentSheet):
            return .paymentSheetDisplayCardBrandDropdownIndicator
        case (.openCardBrandDropdown, .paymentSheet):
            return .paymentSheetOpenCardBrandDropdown
        case (.closeCardBrandDropDown, .paymentSheet):
            return .paymentSheetCloseCardBrandDropDown
        case (.openCardBrandEditScreen, .paymentSheet):
            return .paymentSheetOpenCardBrandEditScreen
        case (.updateCardBrand, .paymentSheet):
            return .paymentSheetUpdateCardBrand
        case (.updateCardBrandFailed, .paymentSheet):
            return .paymentSheetUpdateCardBrandFailed
        case (.closeEditScreen, .paymentSheet):
            return .paymentSheetClosesEditScreen
        case (.displayCardBrandDropdownIndicator, .customerSheet):
            return .customerSheetDisplayCardBrandDropdownIndicator
        case (.openCardBrandDropdown, .customerSheet):
            return .customerSheetOpenCardBrandDropdown
        case (.closeCardBrandDropDown, .customerSheet):
            return .customerSheetCloseCardBrandDropDown
        case (.openCardBrandEditScreen, .customerSheet):
            return .customerSheetOpenCardBrandEditScreen
        case (.updateCardBrand, .customerSheet):
            return .customerSheetUpdateCardBrand
        case (.updateCardBrandFailed, .customerSheet):
            return .customerSheetUpdateCardBrandFailed
        case (.closeEditScreen, .customerSheet):
            return .customerSheetClosesEditScreen
        }
    }

    // Helper for mapping between PaymentSheet and CustomerSheet CBC events
    enum CardBrandChoiceEvents {
        case displayCardBrandDropdownIndicator
        case openCardBrandDropdown
        case closeCardBrandDropDown
        case openCardBrandEditScreen
        case updateCardBrand
        case updateCardBrandFailed
        case closeEditScreen
    }
}
