//
//  PaymentMethodMessagingPromotionsHelper.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/4/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

class PaymentMethodMessagingPromotionsHelper {

    static let supportedPaymentMethods: [PaymentSheet.PaymentMethodType] = [
        .stripe(.afterpayClearpay),
        .stripe(.affirm),
        .stripe(.klarna),
    ]

    struct PromotionContent: Equatable {
        let promotion: String
        let learnMoreText: String
        let infoUrl: URL
    }

    private let elementsSession: STPElementsSession
    private let intent: Intent
    private let configuration: PaymentElementConfiguration
    private let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    // ⚠️ an exposure must be logged before the experiment value is used for any purpose ⚠️
    // ⚠️ do not directly access the property, instead use `experiment` ⚠️
    private let _experiment: PaymentMethodMessagingPromotionsExperiment
    private var exposureLogged = false
    private var experiment: PaymentMethodMessagingPromotionsExperiment {
        if !exposureLogged {
            analyticsHelper.logExposure(experiment: _experiment)
            exposureLogged = true
        }
        return _experiment
    }

    private let promotionsLock = NSLock()
    // null until set by loading
    private var _promotions: [String: PromotionContent]?
    private var promotions: [String: PromotionContent]? {
        get {
            promotionsLock.lock()
            defer { promotionsLock.unlock() }
            return _promotions
        }
        set {
            promotionsLock.lock()
            defer { promotionsLock.unlock() }
            _promotions = newValue
        }
    }

    var isInTreatmentGroup: Bool {
        experiment.group == .treatment
    }

    init(
        elementsSession: STPElementsSession,
        intent: Intent,
        configuration: PaymentElementConfiguration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.elementsSession = elementsSession
        self.intent = intent
        self.configuration = configuration
        self.paymentMethodTypes = paymentMethodTypes
        let layout = configuration.resolveLayout(elementsSession: elementsSession, paymentMethodTypes: paymentMethodTypes)
        self._experiment = PaymentMethodMessagingPromotionsExperiment(elementsSession: elementsSession, layout: layout.rawValue)
        self.analyticsHelper = analyticsHelper
    }

    func fetchData() {
        // Check experiment group, and only proceed if in treatment group
        guard experiment.group == .treatment else {
            return
        }

        // Only fetch data if we have an amount and currency (for example setup mode won't have this)
        guard let amount = intent.amount, let currency = intent.currency else {
            return
        }

        // Generate list of payment methods
        let supportedPaymentMethodTypes: [STPPaymentMethodType] = paymentMethodTypes.compactMap { paymentMethodType in
            guard Self.supportedPaymentMethods.contains(paymentMethodType),
                  case let .stripe(stpPaymentMethodType) = paymentMethodType else {
                return nil
            }
            return stpPaymentMethodType
        }

        // Only fetch data if we have payment method types
        guard !supportedPaymentMethodTypes.isEmpty else {
            return
        }

        // Generate PMME config
        let pmmeConfig = PaymentMethodMessagingElement.Configuration(
            amount: amount,
            currency: currency,
            apiClient: configuration.apiClient,
            locale: Locale.current.identifier,
            countryCode: elementsSession.countryCode,
            paymentMethodTypes: supportedPaymentMethodTypes
        )

        // Fetch data
        Task { @MainActor in
            do {
                let response = try await PaymentMethodMessagingElement.get(configuration: pmmeConfig)
                promotions = response.paymentSheetPromotionContents(apiClient: configuration.apiClient)
            } catch {
                logUnexpectedPMMEError(
                    error: error,
                    apiClient: configuration.apiClient,
                    analyticsClient: STPAnalyticsClient.sharedClient,
                    additionalNonPIIParams: [
                        "failure_reason": "promotion_prefetch_request_failed",
                    ]
                )
                promotions = [:]
            }
        }
    }

    func promotion(for paymentMethodType: PaymentSheet.PaymentMethodType) -> PromotionContent? {
        // get payment method identifier
        guard case let .stripe(stpPaymentMethodType) = paymentMethodType else {
            return nil
        }
        return promotions?[stpPaymentMethodType.identifier]
    }
}

extension PaymentMethodMessagingElement.APIResponse {
    func paymentSheetPromotionContents(
        apiClient: STPAPIClient = STPAPIClient.shared,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) -> [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] {
        var promotionContents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] = [:]

        for paymentPlanGroup in paymentPlanGroups {
            let paymentMethodType = paymentPlanGroup.type.lowercased()

            guard let promotionContent = paymentPlanGroup.makePaymentSheetPromotionContent() else {
                logUnexpectedPMMEError(
                    error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                    apiClient: apiClient,
                    analyticsClient: analyticsClient,
                    additionalNonPIIParams: [
                        "failure_reason": "missing_required_promotion_fields",
                        "payment_method_type": paymentMethodType,
                    ]
                )
                stpAssertionFailure(
                    "Received invalid PMME payment_plan_group for PaymentSheet promotion type '\(paymentMethodType)'; required fields: summary.message, learn_more.message, learn_more.url."
                )
                continue
            }

            guard promotionContents[paymentMethodType] == nil else {
                logUnexpectedPMMEError(
                    error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                    apiClient: apiClient,
                    analyticsClient: analyticsClient,
                    additionalNonPIIParams: [
                        "failure_reason": "duplicate_payment_plan_group_type",
                        "payment_method_type": paymentMethodType,
                    ]
                )
                stpAssertionFailure(
                    "Received duplicate payment_plan_groups.type '\(paymentMethodType)' while building PaymentSheet PMME promotions."
                )
                continue
            }

            promotionContents[paymentMethodType] = promotionContent
        }

        if !paymentPlanGroups.isEmpty && promotionContents.isEmpty {
            logUnexpectedPMMEError(
                error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                apiClient: apiClient,
                analyticsClient: analyticsClient,
                additionalNonPIIParams: [
                    "failure_reason": "all_payment_plan_groups_invalid",
                ]
            )
            stpAssertionFailure(
                "Received \(paymentPlanGroups.count) payment_plan_groups from PMME, but none contained usable PaymentSheet promotion content."
            )
        }

        return promotionContents
    }
}

private extension PaymentMethodMessagingElement.APIResponse.PaymentPlanGroup {
    func makePaymentSheetPromotionContent() -> PaymentMethodMessagingPromotionsHelper.PromotionContent? {
        guard let summary = content.summary?.message,
              let learnMoreText = content.learnMore?.message,
              let infoUrl = content.learnMore?.url else {
            return nil
        }

        return PaymentMethodMessagingPromotionsHelper.PromotionContent(
            promotion: summary,
            learnMoreText: learnMoreText,
            infoUrl: infoUrl
        )
    }
}

private func logUnexpectedPMMEError(
    error: Error,
    apiClient: STPAPIClient,
    analyticsClient: STPAnalyticsClientProtocol,
    additionalNonPIIParams: [String: String]
) {
    let errorAnalytic = ErrorAnalytic(
        event: .unexpectedPMMEError,
        error: error,
        additionalNonPIIParams: additionalNonPIIParams
    )
    analyticsClient.log(analytic: errorAnalytic, apiClient: apiClient)
}
