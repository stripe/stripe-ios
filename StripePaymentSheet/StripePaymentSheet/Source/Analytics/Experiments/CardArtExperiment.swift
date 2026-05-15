//
//  CardArtExperiment.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct CardArtExperiment: LoggableExperiment {
    static let experimentName = "ocs_mobile_card_art"

    let name: String = experimentName
    let arbId: String
    let group: ExperimentGroup

    var dimensions: [String: String] {
        var displayedPaymentMethodTypesIncludingWallets: [String] = displayedPaymentMethodTypes
        displayedPaymentMethodTypesIncludingWallets.append(contentsOf: walletPaymentMethodTypes)
        return [
            "displayed_payment_method_types": displayedPaymentMethodTypes.joined(separator: ","),
            "displayed_payment_method_types_including_wallets": displayedPaymentMethodTypesIncludingWallets.joined(separator: ","),
            "in_app_elements_integration_type": integrationShape,
            "in_app_elements_layout": layout,
            "saved_payment_method_count": String(savedPaymentMethodCount),
            "saved_card_payment_method_count": String(savedCardPaymentMethodCount),
            "saved_card_payment_method_with_card_art_count": String(savedCardPaymentMethodWithCardArtCount),
            "selected_payment_method_type": selectedPaymentMethodType,
            "selected_payment_method_has_card_art": selectedPaymentMethodHasCardArt.description,
        ]
    }

    private let displayedPaymentMethodTypes: [String]
    private let walletPaymentMethodTypes: [String]
    private let integrationShape: String
    private let layout: String
    private let savedPaymentMethodCount: Int
    private let savedCardPaymentMethodCount: Int
    private let savedCardPaymentMethodWithCardArtCount: Int
    private let selectedPaymentMethodType: String
    private let selectedPaymentMethodHasCardArt: Bool

    private init(
        arbId: String,
        group: ExperimentGroup,
        displayedPaymentMethodTypes: [String],
        walletPaymentMethodTypes: [String],
        integrationShape: String,
        layout: String,
        savedPaymentMethodCount: Int,
        savedCardPaymentMethodCount: Int,
        savedCardPaymentMethodWithCardArtCount: Int,
        selectedPaymentMethodType: String,
        selectedPaymentMethodHasCardArt: Bool
    ) {
        self.arbId = arbId
        self.group = group
        self.displayedPaymentMethodTypes = displayedPaymentMethodTypes
        self.walletPaymentMethodTypes = walletPaymentMethodTypes
        self.integrationShape = integrationShape
        self.layout = layout
        self.savedPaymentMethodCount = savedPaymentMethodCount
        self.savedCardPaymentMethodCount = savedCardPaymentMethodCount
        self.savedCardPaymentMethodWithCardArtCount = savedCardPaymentMethodWithCardArtCount
        self.selectedPaymentMethodType = selectedPaymentMethodType
        self.selectedPaymentMethodHasCardArt = selectedPaymentMethodHasCardArt
    }

    /// Creates the card art experiment if available, otherwise returns `nil`
    static func create(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        savedPaymentMethods: [STPPaymentMethod],
        paymentMethodOrientation: PaymentSheet.PaymentMethodLayout.ResolvedLayout,
        selectedPaymentOption: SavedPaymentOptionsViewController.Selection?
    ) -> CardArtExperiment? {
        guard let arbId = elementsSession.experimentsData?.arbId,
              let group = elementsSession.experimentsData?.experimentAssignments[experimentName] else {
            return nil
        }

        let displayedPaymentMethods = paymentMethodTypes.map { $0.identifier }

        var walletTypes: [String] = []
        if PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration) {
            walletTypes.append("apple_pay")
        }
        if PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) {
            walletTypes.append("link")
        }

        let (selectedType, selectedHasCardArt) = selectedPaymentMethodInfo(from: selectedPaymentOption)

        return CardArtExperiment(
            arbId: arbId,
            group: group,
            displayedPaymentMethodTypes: displayedPaymentMethods,
            walletPaymentMethodTypes: walletTypes,
            integrationShape: analyticsHelper.integrationShape.analyticsValue,
            layout: paymentMethodOrientation.rawValue,
            savedPaymentMethodCount: savedPaymentMethods.count,
            savedCardPaymentMethodCount: savedPaymentMethods.filter { $0.type == .card }.count,
            savedCardPaymentMethodWithCardArtCount: savedPaymentMethods.filter { $0.type == .card && $0.cardArtCDNURL() != nil }.count,
            selectedPaymentMethodType: selectedType,
            selectedPaymentMethodHasCardArt: selectedHasCardArt
        )
    }

    private static func selectedPaymentMethodInfo(
        from selection: SavedPaymentOptionsViewController.Selection?
    ) -> (type: String, hasCardArt: Bool) {
        guard let selection else {
            return ("none", false)
        }
        switch selection {
        case .applePay:
            return ("apple_pay", false)
        case .link:
            return ("link", false)
        case .saved(let paymentMethod):
            let hasCardArt = paymentMethod.cardArtCDNURL() != nil
            return (paymentMethod.type.identifier, hasCardArt)
        case .add:
            return ("new", false)
        }
    }
}
