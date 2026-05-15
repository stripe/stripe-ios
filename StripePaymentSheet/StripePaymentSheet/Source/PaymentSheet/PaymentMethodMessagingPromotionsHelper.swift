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

final class PaymentMethodMessagingPromotionsHelper {
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
    private let analyticsHelper: PaymentSheetAnalyticsHelper?
    private let experiment: PaymentMethodMessagingPromotionsExperiment

    private let lock = NSLock()
    private var fetchState: FetchState
    private var fetchTask: Task<Void, Never>?

    init(
        elementsSession: STPElementsSession,
        analyticsHelper: PaymentSheetAnalyticsHelper
    ) {
        self.elementsSession = elementsSession
        self.analyticsHelper = analyticsHelper
        self.experiment = PaymentMethodMessagingPromotionsExperiment(elementsSession: elementsSession)
        self.fetchState = experiment.isInTreatment ? .idle : .completed([:])
        logExposure()
    }

    init(
        experiment: PaymentMethodMessagingPromotionsExperiment,
        analyticsHelper: PaymentSheetAnalyticsHelper? = nil,
        prefetchedPromotionContents: [String: PromotionContent]
    ) {
        self.elementsSession = nil
        self.analyticsHelper = analyticsHelper
        self.experiment = experiment
        self.fetchState = .completed(prefetchedPromotionContents)
    }

    deinit {
        fetchTask?.cancel()
    }

    func prefetchIfNeeded(
        intent: Intent,
        configuration: PaymentElementConfiguration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) {
        guard isTreatmentEnabled() else {
            setFetchState(.completed([:]))
            return
        }
        guard beginLoadingIfIdle() else {
            return
        }
        guard let elementsSession else {
            setFetchState(.completed([:]))
            return
        }
        guard let requestConfiguration = Self.makeConfiguration(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            paymentMethodTypes: paymentMethodTypes
        ) else {
            setFetchState(.completed([:]))
            return
        }

        fetchTask = Task { [weak self] in
            let contents = await Self.fetchPromotionContents(
                configuration: requestConfiguration,
                apiClient: configuration.apiClient
            )
            self?.completeLoading(with: contents)
        }
    }

    func shouldUsePaymentMethodMessagingRow(
        for paymentMethodType: PaymentSheet.PaymentMethodType,
        layout: String? = nil
    ) -> Bool {
        guard isTreatmentEnabled(
            selectedPaymentMethodType: Self.paymentMethodIdentifier(for: paymentMethodType),
            layout: layout
        ) else {
            return false
        }
        return Self.paymentMethodIdentifier(for: paymentMethodType) != nil
    }

    func promotion(
        for paymentMethodType: PaymentSheet.PaymentMethodType,
        layout: String? = nil
    ) -> PromotionContent? {
        guard isTreatmentEnabled(
            selectedPaymentMethodType: Self.paymentMethodIdentifier(for: paymentMethodType),
            layout: layout
        ) else {
            return nil
        }
        guard let identifier = Self.paymentMethodIdentifier(for: paymentMethodType) else {
            return nil
        }
        guard case .completed(let contentsByPaymentMethodType) = getFetchState() else {
            logExposure(
                selectedPaymentMethodType: identifier,
                promotionDisplayedSuccessfully: false,
                layout: layout
            )
            return nil
        }
        let promotionContent = contentsByPaymentMethodType[identifier]
        logExposure(
            selectedPaymentMethodType: identifier,
            promotionDisplayedSuccessfully: promotionContent != nil,
            layout: layout
        )
        return promotionContent
    }

    func completeLoading(with contents: [String: PromotionContent]) {
        setFetchState(.completed(contents))
    }

    private func isTreatmentEnabled(
        selectedPaymentMethodType: String? = nil,
        layout: String? = nil
    ) -> Bool {
        logExposure(
            selectedPaymentMethodType: selectedPaymentMethodType,
            layout: layout
        )
        return experiment.isInTreatment
    }

    private func logExposure(
        selectedPaymentMethodType: String? = nil,
        promotionDisplayedSuccessfully: Bool? = nil,
        layout: String? = nil
    ) {
        let experiment = PaymentMethodMessagingPromotionsExperiment(
            arbId: experiment.arbId,
            group: experiment.group,
            selectedPaymentMethodType: selectedPaymentMethodType,
            promotionDisplayedSuccessfully: promotionDisplayedSuccessfully,
            layout: layout
        )
        analyticsHelper?.logExposure(experiment: experiment)
    }

    private func beginLoadingIfIdle() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard case .idle = fetchState else {
            return false
        }
        fetchState = .loading
        return true
    }

    private func getFetchState() -> FetchState {
        lock.lock()
        defer { lock.unlock() }
        return fetchState
    }

    private func setFetchState(_ fetchState: FetchState) {
        lock.lock()
        defer { lock.unlock() }
        self.fetchState = fetchState
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
