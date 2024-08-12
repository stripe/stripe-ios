//
//  STPCBCController.swift
//  StripePaymentsUI
//
//  Created by David Estes on 11/13/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A controller to handle CBC state
/// Update the `cardNumber` as the card number changes. Brands will be fetched and returned via the `updateHandler()` automatically.
class STPCBCController {
    /// Set this when the card number changes.
    var cardNumber: String? {
        didSet {
            fetchCardBrands()
        }
    }

    var updateHandler: (() -> Void)?

    /// Initialize an STPCBCController.
    /// updateHandler: A block that will be called when the list of available brands updates. Use this to update your UI.
    init(updateHandler: (() -> Void)? = nil) {
        self.updateHandler = updateHandler
    }

    var selectedBrand: STPCardBrand? {
        didSet {
            self.updateHandler?()
        }
    }

    var cardBrands = Set<STPCardBrand>() {
        didSet {
            // If the selected brand does not exist in the current list of brands, reset it
            if let selectedBrand = selectedBrand, !cardBrands.contains(selectedBrand) {
                self.selectedBrand = nil
            }
            // If the selected brand is nil and our preferred brand exists, set that as the selected brand
            if let preferredNetworks = preferredNetworks,
               selectedBrand == nil,
               let preferredBrand = preferredNetworks.first(where: { cardBrands.contains($0) }) {
                self.selectedBrand = preferredBrand
            }
        }
    }

    var preferredNetworks: [STPCardBrand]?

    func fetchCardBrands() {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard cbcEnabled,
              let cardNumber = cardNumber,
              cardNumber.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            if self.cardBrands != Set<STPCardBrand>() {
                self.cardBrands = Set<STPCardBrand>()
                updateHandler?()
            }
            return
        }

        var fetchedCardBrands = Set<STPCardBrand>()
        STPCardValidator.possibleBrands(forNumber: cardNumber) { [weak self] result in
            switch result {
            case .success(let brands):
                fetchedCardBrands = brands
            case .failure:
                // If we fail to fetch card brands fall back to normal card brand detection
                fetchedCardBrands = Set<STPCardBrand>()
            }

            if self?.cardBrands != fetchedCardBrands {
                self?.cardBrands = fetchedCardBrands
                self?.updateHandler?()
            }
        }
    }

    var cbcEnabledOverride: Bool?

    var onBehalfOf: String?

    var cbcEnabled: Bool {
        if let cbcEnabledOverride = cbcEnabledOverride {
            return cbcEnabledOverride
        }
        return CardElementConfigService.shared.isCBCEligible(onBehalfOf: onBehalfOf)
    }

    enum BrandState: Equatable {
        case brand(STPCardBrand)
        case cbcBrandSelected(STPCardBrand)
        case unknown
        case unknownMultipleOptions

        var isCBC: Bool {
            switch self {
            case .brand, .unknown:
                return false
            case .cbcBrandSelected, .unknownMultipleOptions:
                return true
            }
        }

        var brand: STPCardBrand {
            switch self {
            case .brand(let brand):
                return brand
            case .cbcBrandSelected(let brand):
                return brand
            case .unknown, .unknownMultipleOptions:
                return .unknown
            }
        }
    }

    var brandState: BrandState {
        if cbcEnabled {
            if cardBrands.count > 1 {
                if let selectedBrand = selectedBrand {
                    return .cbcBrandSelected(selectedBrand)
                }
                return .unknownMultipleOptions
            }
            if let cardBrand = cardBrands.first {
                return .brand(cardBrand)
            }
            return .unknown
        } else {
            // Otherwise, return the brand for the number
            return .brand(STPCardValidator.brand(forNumber: cardNumber ?? ""))
        }
    }

    // Instead of validating against the selected brand (for CBC purposes),
    // validate CVCs against the default brand of the PAN.
    // We can assume that the CVC length will not change based on the choice of card brand.
    var brandForCVC: STPCardBrand {
        return STPCardValidator.brand(forNumber: cardNumber ?? "")
    }

    var contextMenuConfiguration: UIContextMenuConfiguration {
        return UIContextMenuConfiguration(actionProvider: { _ in
            let action = { (action: UIAction) in
                let brand = STPCard.brand(from: action.identifier.rawValue)
                // Set the selected brand if a brand is selected
                self.selectedBrand = brand != .unknown ? brand : nil
            }
            let placeholderAction = UIAction(title: String.Localized.card_brand_dropdown_placeholder, attributes: .disabled, handler: action)
            let menu = UIMenu(children:
                  [placeholderAction] +
                  self.cardBrands.enumerated().map { (_, brand) in
                        let brandString = STPCard.string(from: brand)
                        return UIAction(title: brandString, image: STPImageLibrary.unpaddedCardBrandImage(for: brand), identifier: .init(rawValue: brandString), state: self.selectedBrand == brand ? .on : .off, handler: action)
                }
            )
            return menu
        })
    }

}
