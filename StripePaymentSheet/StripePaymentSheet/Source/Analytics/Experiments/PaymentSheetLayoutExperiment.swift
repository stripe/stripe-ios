//
//  PaymentSheetLayoutExperiment.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 1/6/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct PaymentSheetLayoutExperiment {
    let group: ExperimentGroup

    let displayedPaymentMethodTypes: [String]
    let walletPaymentMethodTypes: [String]
    let hasSPM: Bool
    let integrationShape: String

    var dimensionsDictionary: [String: Any] {
        var displayedPaymentMethodTypesIncludingWallets: [String] = displayedPaymentMethodTypes
        displayedPaymentMethodTypesIncludingWallets.append(contentsOf: walletPaymentMethodTypes)
        return [
            "displayed_payment_method_types": displayedPaymentMethodTypes,
            "has_saved_payment_method": hasSPM,
            "displayed_payment_method_types_including_wallets": displayedPaymentMethodTypesIncludingWallets,
            "in_app_elements_integration_type": integrationShape,
        ]
    }

    init(
        experimentName: String,
        elementsSession: STPElementsSession,
        displayedPaymentMethodTypes: [String],
        walletPaymentMethodTypes: [String],
        hasSPM: Bool,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        // In some scenarios (i.e. testmode) there will be no group assignment.
        // Treat these scenarios as though we're in the control group.
        let assignment = elementsSession.experimentsData?.experimentAssignments[experimentName]
        self.group = assignment ?? .control
        self.displayedPaymentMethodTypes = displayedPaymentMethodTypes
        self.walletPaymentMethodTypes = walletPaymentMethodTypes
        self.hasSPM = hasSPM
        self.integrationShape = {
            switch integrationShape {
            case .complete:
                return "complete"
            case .flowController:
                return "custom"
            case .embedded:
                return "embedded"
            default:
                return integrationShape.analyticsValue
            }
        }()
    }
}

struct OCSMobileHorizontalModeAA: LoggableExperiment {
    static let experimentName = "ocs_mobile_horizontal_mode_aa"
    private let experiment: PaymentSheetLayoutExperiment

    let name: String = experimentName
    let arbId: String

    var group: ExperimentGroup {
        experiment.group
    }

    var dimensions: [String: Any] {
        experiment.dimensionsDictionary
    }

    init(
        arbId: String,
        elementsSession: STPElementsSession,
        displayedPaymentMethodTypes: [String],
        walletPaymentMethodTypes: [String],
        hasSPM: Bool,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        let experiment = PaymentSheetLayoutExperiment(
            experimentName: Self.experimentName,
            elementsSession: elementsSession,
            displayedPaymentMethodTypes: displayedPaymentMethodTypes,
            walletPaymentMethodTypes: walletPaymentMethodTypes,
            hasSPM: hasSPM,
            integrationShape: integrationShape
        )

        self.arbId = arbId
        self.experiment = experiment
    }
}
