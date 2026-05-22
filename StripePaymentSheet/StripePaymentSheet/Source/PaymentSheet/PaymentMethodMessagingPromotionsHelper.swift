//
//  PaymentMethodMessagingPromotionsHelper.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/4/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

private let paymentSheetPMMESupportedPaymentMethodTypes: [STPPaymentMethodType] = [
    .afterpayClearpay,
    .affirm,
    .klarna,
]
private let paymentSheetPMMESupportedPaymentMethodIdentifiers = Set(paymentSheetPMMESupportedPaymentMethodTypes.map(\.identifier))

@MainActor
final class PaymentMethodMessagingPromotionsHelper {

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

    private enum FetchState: Equatable {
        case idle
        case loading
        case completed([String: PromotionContent])
    }

    private let elementsSession: STPElementsSession?
    let experiment: PaymentMethodMessagingPromotionsExperiment

    var isInTreatmentGroup: Bool {
        experiment.isInTreatment
    }

    private var fetchState: FetchState
    private var fetchTask: Task<Void, Never>?

    init(elementsSession: STPElementsSession) {
        self.elementsSession = elementsSession
        self.experiment = PaymentMethodMessagingPromotionsExperiment(elementsSession: elementsSession)
        self.fetchState = experiment.isInTreatment ? .idle : .completed([:])
    }

    init(
        experiment: PaymentMethodMessagingPromotionsExperiment,
        prefetchedPromotionContents: [String: PromotionContent]
    ) {
        self.elementsSession = nil
        self.experiment = experiment
        self.fetchState = .completed(prefetchedPromotionContents)
    }

    func prefetchIfNeeded(
        intent: Intent,
        configuration: PaymentElementConfiguration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) {
        guard experiment.isInTreatment else {
            fetchState = .completed([:])
            return
        }
        guard beginLoadingIfIdle() else {
            return
        }
        guard let elementsSession else {
            fetchState = .completed([:])
            return
        }
        guard let requestConfiguration = Self.makeConfiguration(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            paymentMethodTypes: paymentMethodTypes
        ) else {
            fetchState = .completed([:])
            return
        }

        fetchTask = Task { [weak self] in
            let contents = await Self.fetchPromotionContents(
                configuration: requestConfiguration,
                apiClient: configuration.apiClient
            )
            await MainActor.run {
                self?.fetchState = .completed(contents)
            }
        }
    }

    func promotion(for paymentMethodType: PaymentSheet.PaymentMethodType) -> PromotionContent? {
        guard experiment.isInTreatment else {
            return nil
        }
        guard let identifier = Self.paymentMethodIdentifier(for: paymentMethodType) else {
            return nil
        }
        guard case .completed(let contentsByPaymentMethodType) = fetchState else {
            return nil
        }
        return contentsByPaymentMethodType[identifier]
    }

    private func beginLoadingIfIdle() -> Bool {
        guard case .idle = fetchState else {
            return false
        }
        fetchState = .loading
        return true
    }

    private static func makeConfiguration(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) -> PaymentMethodMessagingElement.Configuration? {
        guard let amount = intent.amount, let currency = intent.currency else {
            return nil
        }

        let supportedPaymentMethodTypes: [STPPaymentMethodType] = paymentMethodTypes.compactMap { paymentMethodType in
            guard case let .stripe(stpPaymentMethodType) = paymentMethodType else {
                return nil
            }
            guard paymentSheetPMMESupportedPaymentMethodTypes.contains(stpPaymentMethodType) else {
                return nil
            }
            return stpPaymentMethodType
        }
        guard !supportedPaymentMethodTypes.isEmpty else {
            return nil
        }

        return PaymentMethodMessagingElement.Configuration(
            amount: amount,
            currency: currency,
            apiClient: configuration.apiClient,
            locale: Locale.current.identifier,
            countryCode: elementsSession.countryCode,
            paymentMethodTypes: supportedPaymentMethodTypes
        )
    }

    private static func paymentMethodIdentifier(for paymentMethodType: PaymentSheet.PaymentMethodType) -> String? {
        guard case let .stripe(stpPaymentMethodType) = paymentMethodType else {
            return nil
        }
        guard paymentSheetPMMESupportedPaymentMethodTypes.contains(stpPaymentMethodType) else {
            return nil
        }
        return stpPaymentMethodType.identifier
    }

    private static func fetchPromotionContents(
        configuration: PaymentMethodMessagingElement.Configuration,
        apiClient: STPAPIClient
    ) async -> [String: PromotionContent] {
        do {
            let response = try await PaymentMethodMessagingElement.get(configuration: configuration)
            return response.paymentSheetPromotionContents(apiClient: apiClient)
        } catch {
            logUnexpectedPMMEError(
                error: error,
                apiClient: apiClient,
                analyticsClient: STPAnalyticsClient.sharedClient,
                additionalNonPIIParams: [
                    "failure_reason": "promotion_prefetch_request_failed",
                ]
            )
            return [:]
        }
    }
}

extension PaymentMethodMessagingElement.APIResponse {
    func paymentSheetPromotionContents(
        apiClient: STPAPIClient = STPAPIClient.shared,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) -> [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] {
        var promotionContents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] = [:]

        for paymentPlanGroup in paymentPlanGroups {
            let rawType = paymentPlanGroup.type
            let normalizedType = rawType.lowercased()

            guard paymentSheetPMMESupportedPaymentMethodIdentifiers.contains(normalizedType) else {
                logUnexpectedPMMEError(
                    error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                    apiClient: apiClient,
                    analyticsClient: analyticsClient,
                    additionalNonPIIParams: [
                        "failure_reason": "unsupported_payment_plan_group_type",
                        "payment_method_type": normalizedType,
                    ]
                )
                stpAssertionFailure(
                    "Received unsupported payment_plan_groups.type '\(rawType)' while building PaymentSheet PMME promotions."
                )
                continue
            }

            guard let promotionContent = paymentPlanGroup.makePaymentSheetPromotionContent() else {
                logUnexpectedPMMEError(
                    error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                    apiClient: apiClient,
                    analyticsClient: analyticsClient,
                    additionalNonPIIParams: [
                        "failure_reason": "missing_required_promotion_fields",
                        "payment_method_type": normalizedType,
                    ]
                )
                stpAssertionFailure(
                    "Received invalid PMME payment_plan_group for PaymentSheet promotion type '\(rawType)'; required fields: summary.message, learn_more.message, learn_more.url."
                )
                continue
            }

            guard promotionContents[normalizedType] == nil else {
                logUnexpectedPMMEError(
                    error: PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI,
                    apiClient: apiClient,
                    analyticsClient: analyticsClient,
                    additionalNonPIIParams: [
                        "failure_reason": "duplicate_payment_plan_group_type",
                        "payment_method_type": normalizedType,
                    ]
                )
                stpAssertionFailure(
                    "Received duplicate payment_plan_groups.type '\(rawType)' while building PaymentSheet PMME promotions."
                )
                continue
            }

            promotionContents[normalizedType] = promotionContent
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
