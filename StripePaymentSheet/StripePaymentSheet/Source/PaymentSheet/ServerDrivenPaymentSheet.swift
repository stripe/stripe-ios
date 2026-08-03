//
//  ServerDrivenPaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Stripe on 6/3/26.
//

import Foundation
import ObjectiveC
@_spi(STP) import StripeCore

/// A validated, renderer-facing view of the generated Mobile Session response.
struct ServerDrivenPaymentSheetResponse {
    enum Error: Swift.Error, AnalyticLoggableError {
        case unsupportedContractMajor(Int)
        case unsupportedFeatureValue(String)
        case unsupportedFormElement(String)
        case malformedFormElement(String)
        case invalidAssetURL(String)
        case invalidAssetCatalog
        case missingAsset(String)
        case invalidFormSpec
        case missingFormSpec(String)
        case collectionBounds
        case fieldBounds

        var analyticsErrorType: String {
            "mobile_session_contract_error"
        }

        var analyticsErrorCode: String {
            switch self {
            case .unsupportedContractMajor: return "unsupported_contract_major"
            case .unsupportedFeatureValue: return "unsupported_feature_value"
            case .unsupportedFormElement: return "unsupported_form_element"
            case .malformedFormElement: return "malformed_form_element"
            case .invalidAssetURL: return "invalid_asset_url"
            case .invalidAssetCatalog: return "invalid_asset_catalog"
            case .missingAsset: return "missing_asset"
            case .invalidFormSpec: return "invalid_form_spec"
            case .missingFormSpec: return "missing_form_spec"
            case .collectionBounds: return "collection_bounds"
            case .fieldBounds: return "field_bounds"
            }
        }
    }

    let contractMajor: Int
    let contractRevision: String
    let features: Features
    let paymentMethodTypes: [String]
    let paymentMethodCodes: [String: String]
    let assets: Assets
    let formSpecs: [[String: Any]]

    init(
        contractMajor: Int = MobileSessionContractV1.contractMajor,
        contractRevision: String = MobileSessionContractV1.contractRevision,
        features: Features,
        paymentMethodTypes: [String],
        paymentMethodCodes: [String: String]? = nil,
        assets: Assets,
        formSpecs: [[String: Any]]
    ) {
        self.contractMajor = contractMajor
        self.contractRevision = contractRevision
        self.features = features
        self.paymentMethodTypes = paymentMethodTypes
        self.paymentMethodCodes = paymentMethodCodes ?? paymentMethodTypes.reduce(into: [:]) { result, type in
            result[type] = type
        }
        self.assets = assets
        self.formSpecs = formSpecs
    }

    init(mobilePaymentElement: MobilePaymentElementV1) throws {
        guard mobilePaymentElement.contract.major == MobileSessionContractV1.contractMajor else {
            throw Error.unsupportedContractMajor(mobilePaymentElement.contract.major)
        }
        try Self.validateBounds(mobilePaymentElement)

        contractMajor = mobilePaymentElement.contract.major
        contractRevision = mobilePaymentElement.contract.revision
        features = try Features(mobilePaymentElement.features)
        paymentMethodTypes = mobilePaymentElement.paymentMethodAvailability
        paymentMethodCodes = mobilePaymentElement.formSpecs.reduce(into: [:]) { result, formSpec in
            result[formSpec.type] = formSpec.paymentMethodCode ?? formSpec.type
        }
        let availablePaymentMethodTypes = Set(paymentMethodTypes)
        guard availablePaymentMethodTypes.count == paymentMethodTypes.count else {
            throw Error.invalidFormSpec
        }

        let assetPaymentMethodTypeList = mobilePaymentElement.assets.paymentMethods.map(\.paymentMethodType)
        let assetPaymentMethodTypes = Set(assetPaymentMethodTypeList)
        guard assetPaymentMethodTypes.count == assetPaymentMethodTypeList.count else {
            throw Error.invalidAssetCatalog
        }
        if let missingAssetType = paymentMethodTypes.first(where: { !assetPaymentMethodTypes.contains($0) }) {
            throw Error.missingAsset(missingAssetType)
        }
        guard assetPaymentMethodTypes == availablePaymentMethodTypes else {
            throw Error.invalidAssetCatalog
        }
        assets = try Assets(mobilePaymentElement.assets)
        formSpecs = try mobilePaymentElement.formSpecs.map { try $0.formSpecDictionary() }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        for formSpec in formSpecs {
            let data = try JSONSerialization.data(withJSONObject: formSpec)
            guard (try? decoder.decode(FormSpec.self, from: data)) != nil else {
                throw Error.invalidFormSpec
            }
        }
        let formSpecTypes = Set(mobilePaymentElement.formSpecs.map(\.type))
        guard formSpecTypes.count == mobilePaymentElement.formSpecs.count else {
            throw Error.invalidFormSpec
        }
        if let missingPaymentMethodType = paymentMethodTypes.first(where: { !formSpecTypes.contains($0) }) {
            throw Error.missingFormSpec(missingPaymentMethodType)
        }
        guard formSpecTypes == availablePaymentMethodTypes else {
            throw Error.invalidFormSpec
        }
    }

    private static func validateBounds(_ response: MobilePaymentElementV1) throws {
        guard response.paymentMethodAvailability.count <= 100,
              response.assets.paymentMethods.count <= 100,
              response.formSpecs.count <= 100,
              response.paymentMethodAvailability.allSatisfy({ $0.isWithin(100) })
        else {
            throw Error.collectionBounds
        }
        for asset in response.assets.paymentMethods {
            guard asset.paymentMethodType.isWithin(100),
                  asset.locale.isWithin(35),
                  asset.displayName.isWithin(200)
            else {
                throw Error.fieldBounds
            }
        }
        for formSpec in response.formSpecs {
            guard formSpec.type.isWithin(100),
                  formSpec.paymentMethodCode?.isWithin(100) != false,
                  formSpec.fields.count <= 100
            else {
                throw Error.collectionBounds
            }
            for field in formSpec.fields {
                guard field.items.count <= 100,
                      (field.allowedCountryCodes?.count ?? 0) <= 249,
                      field.apiPath?.isWithin(500) != false,
                      field.translationId?.isWithin(200) != false,
                      field.subtitle?.isWithin(500) != false,
                      field.localizedTextTemplate?.isWithin(5_000) != false,
                      field.items.allSatisfy({ option in
                          option.displayText.isWithin(200) && option.apiValue?.isWithin(200) != false
                      })
                else {
                    throw Error.fieldBounds
                }
            }
        }
    }

    struct Features: Equatable {
        enum FinancialConnectionsLite: Equatable {
            case automatic
            case disabled
            case preferred

            var fcLiteKillswitchEnabled: Bool {
                self == .disabled
            }

            var remoteFcLiteOverrideEnabled: Bool {
                self == .preferred
            }
        }

        static let defaults = Features(
            financialConnectionsLite: .automatic,
            linkGlobalHoldbackLookup: true,
            forceVerticalPaymentMethodLayout: false,
            cardFundingFiltering: false
        )

        let financialConnectionsLite: FinancialConnectionsLite
        let linkGlobalHoldbackLookup: Bool
        let forceVerticalPaymentMethodLayout: Bool
        let cardFundingFiltering: Bool

        init(_ generated: MobilePaymentElementFeaturesV1) throws {
            switch generated.financialConnectionsLite {
            case "automatic":
                financialConnectionsLite = .automatic
            case "disabled":
                financialConnectionsLite = .disabled
            case "preferred":
                financialConnectionsLite = .preferred
            default:
                throw Error.unsupportedFeatureValue(generated.financialConnectionsLite)
            }
            linkGlobalHoldbackLookup = generated.linkGlobalHoldbackLookup
            forceVerticalPaymentMethodLayout = generated.forceVerticalPaymentMethodLayout
            cardFundingFiltering = generated.cardFundingFiltering
        }

        init(
            financialConnectionsLite: FinancialConnectionsLite,
            linkGlobalHoldbackLookup: Bool,
            forceVerticalPaymentMethodLayout: Bool,
            cardFundingFiltering: Bool
        ) {
            self.financialConnectionsLite = financialConnectionsLite
            self.linkGlobalHoldbackLookup = linkGlobalHoldbackLookup
            self.forceVerticalPaymentMethodLayout = forceVerticalPaymentMethodLayout
            self.cardFundingFiltering = cardFundingFiltering
        }
    }

    struct Assets {
        let paymentMethodDisplayNames: [String: String]
        let selectorIconURLs: [String: ValidatedSelectorIcon]

        struct ValidatedSelectorIcon {
            let lightThemePNG: String
            let darkThemePNG: String?
        }

        init(
            paymentMethodDisplayNames: [String: String],
            selectorIconURLs: [String: ValidatedSelectorIcon]
        ) {
            self.paymentMethodDisplayNames = paymentMethodDisplayNames
            self.selectorIconURLs = selectorIconURLs
        }

        init(_ generated: MobilePaymentElementAssetsV1) throws {
            var displayNames: [String: String] = [:]
            var selectorIcons: [String: ValidatedSelectorIcon] = [:]
            for asset in generated.paymentMethods {
                displayNames[asset.paymentMethodType] = asset.displayName
                if let icon = asset.selectorIcon {
                    selectorIcons[asset.paymentMethodType] = try ValidatedSelectorIcon(icon)
                }
            }
            paymentMethodDisplayNames = displayNames
            selectorIconURLs = selectorIcons
        }
    }
}

private extension ServerDrivenPaymentSheetResponse.Assets.ValidatedSelectorIcon {
    static let approvedHosts: Set<String> = ["js.stripe.com", "files.stripe.com"]

    init(_ generated: SelectorIconV1) throws {
        try Self.validate(generated.lightThemePng)
        if let darkThemePng = generated.darkThemePng {
            try Self.validate(darkThemePng)
        }
        lightThemePNG = generated.lightThemePng
        darkThemePNG = generated.darkThemePng
    }

    static func validate(_ value: String) throws {
        guard value.count <= 2_048,
              let url = URL(string: value),
              url.scheme == "https",
              url.host.map({ approvedHosts.contains($0.lowercased()) }) == true
        else {
            throw ServerDrivenPaymentSheetResponse.Error.invalidAssetURL(value)
        }
    }
}

private extension String {
    func isWithin(_ maximumLength: Int) -> Bool {
        !isEmpty && count <= maximumLength
    }
}

private extension PaymentMethodFormSpecV1 {
    func formSpecDictionary() throws -> [String: Any] {
        var dictionary: [String: Any] = try [
            "type": type,
            "fields": fields.map { try $0.formElementDictionary() },
            "requires_form_screen": requiresFormScreen,
        ]
        if let selectorIcon {
            dictionary["selector_icon"] = try selectorIcon.formSpecDictionary()
        }
        return dictionary
    }
}

private extension SelectorIconV1 {
    func formSpecDictionary() throws -> [String: Any] {
        try ServerDrivenPaymentSheetResponse.Assets.ValidatedSelectorIcon.validate(lightThemePng)
        var dictionary: [String: Any] = ["light_theme_png": lightThemePng]
        if let darkThemePng {
            try ServerDrivenPaymentSheetResponse.Assets.ValidatedSelectorIcon.validate(darkThemePng)
            dictionary["dark_theme_png"] = darkThemePng
        }
        return dictionary
    }
}

private extension FormElementSpecV1 {
    static let supportedTypes: Set<String> = [
        "name", "email", "selector", "billing_address", "country",
        "affirm_header", "klarna_header", "klarna_country",
        "au_becs_bsb_number", "au_becs_account_number", "au_becs_mandate",
        "afterpay_header", "iban", "sepa_mandate",
        "bacs_debit_bank_account", "bacs_debit_mandate", "boleto_tax_id",
        "konbini_confirmation_number", "placeholder",
        "native_component", "mandate_text",
    ]

    func formElementDictionary() throws -> [String: Any] {
        guard Self.supportedTypes.contains(type) else {
            throw ServerDrivenPaymentSheetResponse.Error.unsupportedFormElement(type)
        }
        if type == "placeholder", placeholderFor == nil {
            throw ServerDrivenPaymentSheetResponse.Error.malformedFormElement(type)
        }
        if type == "native_component", component == nil {
            throw ServerDrivenPaymentSheetResponse.Error.malformedFormElement(type)
        }
        if type == "mandate_text" {
            guard localizedTextTemplate != nil || textKey != nil else {
                throw ServerDrivenPaymentSheetResponse.Error.malformedFormElement(type)
            }
            if let localizedTextTemplate {
                let placeholder = "{{merchant_display_name}}"
                let withoutMerchantPlaceholder = localizedTextTemplate.replacingOccurrences(
                    of: placeholder,
                    with: ""
                )
                guard localizedTextTemplate.contains(placeholder),
                      !withoutMerchantPlaceholder.contains("{{"),
                      !withoutMerchantPlaceholder.contains("}}"),
                      !localizedTextTemplate.contains("<"),
                      !localizedTextTemplate.contains(">")
                else {
                    throw ServerDrivenPaymentSheetResponse.Error.malformedFormElement(type)
                }
            }
        }

        var dictionary: [String: Any] = ["type": type]
        if let apiPath {
            dictionary["api_path"] = ["v1": apiPath]
        }
        if let translationId {
            dictionary["translation_id"] = translationId
        }
        if !items.isEmpty {
            dictionary["items"] = items.map { option in
                var value: [String: Any] = ["display_text": option.displayText]
                value["api_value"] = option.apiValue
                return value
            }
        }
        dictionary["allowed_country_codes"] = allowedCountryCodes
        dictionary["for"] = placeholderFor
        dictionary["component"] = component
        dictionary["subtitle"] = subtitle
        dictionary["disable_billing_detail_collection"] = disableBillingDetailCollection
        dictionary["text_key"] = textKey
        dictionary["localized_text_template"] = localizedTextTemplate
        dictionary["setup_future_usage_required"] = setupFutureUsageRequired
        return dictionary
    }
}

final class ServerDrivenPaymentSheetAssetStore {
    static let shared = ServerDrivenPaymentSheetAssetStore()

    private var paymentMethodDisplayNames: [String: String] = [:]
    private let lock = NSLock()

    func install(_ assets: ServerDrivenPaymentSheetResponse.Assets) {
        lock.lock()
        paymentMethodDisplayNames = assets.paymentMethodDisplayNames
        lock.unlock()
    }

    func displayName(for paymentMethodType: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return paymentMethodDisplayNames[paymentMethodType]
    }
}

private var serverDrivenPaymentSheetAssociationKey: UInt8 = 0

extension STPElementsSession {
    var serverDrivenPaymentSheet: ServerDrivenPaymentSheetResponse? {
        get {
            objc_getAssociatedObject(self, &serverDrivenPaymentSheetAssociationKey) as? ServerDrivenPaymentSheetResponse
        }
        set {
            objc_setAssociatedObject(
                self,
                &serverDrivenPaymentSheetAssociationKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var serverDrivenFeatures: ServerDrivenPaymentSheetResponse.Features {
        serverDrivenPaymentSheet?.features ?? .defaults
    }
}
