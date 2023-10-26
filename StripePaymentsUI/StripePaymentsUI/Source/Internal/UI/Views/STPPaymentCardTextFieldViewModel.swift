//
//  STPPaymentCardTextFieldViewModel.swift
//  StripePaymentsUI
//
//  Created by Jack Flintermann on 7/21/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
import UIKit

@objc enum STPCardFieldType: Int {
    case number
    case expiration
    case CVC
    case postalCode
}

class STPPaymentCardTextFieldViewModel: NSObject {
    private var _cardNumber: String?
    @objc dynamic var cardNumber: String? {
        get {
            _cardNumber
        }
        set(cardNumber) {
            let sanitizedNumber = STPCardValidator.sanitizedNumericString(for: cardNumber ?? "")
            hasCompleteMetadataForCardNumber = STPBINController.shared.hasBINRanges(
                forPrefix: sanitizedNumber
            )
            if hasCompleteMetadataForCardNumber {
                let brand = STPCardValidator.brand(forNumber: sanitizedNumber)
                let maxLength = STPCardValidator.maxLength(for: brand)
                _cardNumber = sanitizedNumber.stp_safeSubstring(to: maxLength)
            } else {
                _cardNumber = sanitizedNumber.stp_safeSubstring(
                    to: Int(STPBINController.shared.maxCardNumberLength())
                )
            }
        }
    }

    @objc var rawExpiration: String? {
        get {
            var array: [String] = []
            if expirationMonth != nil && !(expirationMonth == "") {
                array.append(expirationMonth ?? "")
            }

            if STPCardValidator.validationState(forExpirationMonth: expirationMonth ?? "") == .valid
            {
                array.append(expirationYear ?? "")
            }
            return array.joined(separator: "/")
        }
        set(expiration) {
            let sanitizedExpiration = STPCardValidator.sanitizedNumericString(for: expiration ?? "")
            expirationMonth = sanitizedExpiration.stp_safeSubstring(to: 2)
            expirationYear = sanitizedExpiration.stp_safeSubstring(from: 2).stp_safeSubstring(to: 2)
        }
    }

    private var _cvc: String?
    @objc dynamic var cvc: String? {
        get {
            _cvc
        }
        set(cvc) {
            let maxLength = STPCardValidator.maxCVCLength(for: brand)
            _cvc = STPCardValidator.sanitizedNumericString(for: cvc ?? "").stp_safeSubstring(
                to: Int(maxLength)
            )
        }
    }
    @objc dynamic var postalCodeRequested = false

    var postalCodeRequired: Bool {
        return postalCodeRequested
            && STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: postalCodeCountryCode)
    }

    private var _postalCode: String?
    var postalCode: String? {
        get {
            _postalCode
        }
        set(postalCode) {
            _postalCode = STPPostalCodeValidator.formattedSanitizedPostalCode(
                from: postalCode,
                countryCode: postalCodeCountryCode,
                usage: .cardField
            )
        }
    }

    private var _postalCodeCountryCode: String?
    @objc dynamic var postalCodeCountryCode: String? {
        get {
            _postalCodeCountryCode
        }
        set(postalCodeCountryCode) {
            _postalCodeCountryCode = postalCodeCountryCode
            postalCode = STPPostalCodeValidator.formattedSanitizedPostalCode(
                from: postalCode,
                countryCode: postalCodeCountryCode,
                usage: .cardField
            )
        }
    }

    enum BrandState {
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

    @objc dynamic var brand: STPCardBrand {
        switch brandState {
        case .brand(let brand):
            return brand
        case .cbcBrandSelected(let brand):
            return brand
        case .unknown, .unknownMultipleOptions:
            return .unknown
        }
    }

    @objc dynamic var isValid: Bool {
        return STPCardValidator.validationState(
            forNumber: cardNumber ?? "",
            validatingCardBrand: true
        )
            == .valid && hasCompleteMetadataForCardNumber
            && validationStateForExpiration() == .valid
            && validationStateForCVC() == .valid
            && (!postalCodeRequired || validationStateForPostalCode() == .valid)
    }
    @objc dynamic private(set) var hasCompleteMetadataForCardNumber = false

    var isNumberMaxLength: Bool {
        return (cardNumber?.count ?? 0) == STPBINController.shared.maxCardNumberLength()
    }

    func defaultPlaceholder() -> String {
        return "4242424242424242"
    }

    func compressedCardNumber(withPlaceholder placeholder: String?) -> String? {
        var cardNumber = self.cardNumber
        if (cardNumber?.count ?? 0) == 0 {
            cardNumber = placeholder ?? defaultPlaceholder()
        }

        // use the card number format
        let cardNumberFormat = STPCardValidator.cardNumberFormat(forCardNumber: cardNumber ?? "")

        var index = 0
        for segment in cardNumberFormat {
            let segmentLength = Int(segment.uintValue)
            if index + segmentLength >= (cardNumber?.count ?? 0) {
                return cardNumber?.stp_safeSubstring(from: index)
            }
            index += segmentLength
        }

        let length = Int(cardNumberFormat.last?.uintValue ?? 0)
        index = (cardNumber?.count ?? 0) - length

        if index < (cardNumber?.count ?? 0) {
            return cardNumber?.stp_safeSubstring(from: index)
        }

        return nil
    }

    func validationStateForExpiration() -> STPCardValidationState {
        let monthState = STPCardValidator.validationState(forExpirationMonth: expirationMonth ?? "")
        let yearState = STPCardValidator.validationState(
            forExpirationYear: expirationYear ?? "",
            inMonth: expirationMonth ?? ""
        )
        if monthState == .valid && yearState == .valid {
            return .valid
        } else if monthState == .invalid || yearState == .invalid {
            return .invalid
        } else {
            return .incomplete
        }
    }

    func validationStateForCVC() -> STPCardValidationState {
        return STPCardValidator.validationState(forCVC: cvc ?? "", cardBrand: brand)
    }

    func validationStateForPostalCode() -> STPCardValidationState {
        if (postalCode?.count ?? 0) > 0 {
            return .valid
        } else {
            return .incomplete
        }
    }

    func validationStateForCardNumber(handler: @escaping (STPCardValidationState) -> Void) {
        STPBINController.shared.retrieveBINRanges(forPrefix: cardNumber ?? "") { _ in
            self.hasCompleteMetadataForCardNumber = STPBINController.shared.hasBINRanges(
                forPrefix: self.cardNumber ?? ""
            )
            handler(
                STPCardValidator.validationState(
                    forNumber: self.cardNumber ?? "",
                    validatingCardBrand: true
                )
            )
        }
    }

    var cbcEnabledOverride: Bool? = {
        // TODO: Remove the default value of `false` once we release CBC
        return false
    }()

    var cbcEnabled: Bool {
        if let cbcEnabledOverride = cbcEnabledOverride {
            return cbcEnabledOverride
        }
        return CardElementConfigService.shared.isCBCEligible
    }

    private var _expirationMonth: String?
    @objc private(set) var expirationMonth: String? {
        get {
            _expirationMonth
        }
        set {
            // This might contain slashes.
            var sanitizedExpiration = STPCardValidator.sanitizedNumericString(for: newValue ?? "")
            if sanitizedExpiration.count == 1 && !(sanitizedExpiration == "0")
                && !(sanitizedExpiration == "1")
            {
                sanitizedExpiration = "0" + sanitizedExpiration
            }
            _expirationMonth = sanitizedExpiration.stp_safeSubstring(to: 2)
        }
    }
    private var _expirationYear: String?
    @objc private(set) dynamic var expirationYear: String? {
        get {
            _expirationYear
        }
        set {
            _expirationYear = STPCardValidator.sanitizedNumericString(for: newValue ?? "")
                .stp_safeSubstring(to: 2)

        }
    }

    var selectedBrand: STPCardBrand?

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

    func fetchCardBrands(handler: @escaping (Set<STPCardBrand>) -> Void) {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard let cardNumber = cardNumber,
              cardNumber.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            if self.cardBrands != Set<STPCardBrand>() {
                self.cardBrands = Set<STPCardBrand>()
                handler(cardBrands)
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
                handler(fetchedCardBrands)
            }
        }
    }

    @objc
    public class func keyPathsForValuesAffectingIsValid() -> Set<String> {
        return Set<String>([
            "cardNumber",
            "expirationMonth",
            "expirationYear",
            "cvc",
            "brand",
            "postalCode",
            "postalCodeRequested",
            "postalCodeCountryCode",
            "hasCompleteMetadataForCardNumber",
        ])
    }
}
