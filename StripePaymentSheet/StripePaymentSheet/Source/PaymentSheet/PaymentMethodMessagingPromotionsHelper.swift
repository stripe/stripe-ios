//
//  PaymentMethodMessagingPromotionsHelper.swift
//  StripePaymentSheet
//
//  Created by George Birch on 5/4/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

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

    fileprivate static let supportedPaymentMethodTypes: [STPPaymentMethodType] = [
        .afterpayClearpay,
        .affirm,
        .klarna,
    ]
    fileprivate static let supportedPaymentMethodIdentifiers = Set(supportedPaymentMethodTypes.map(\.identifier))

    let experiment: PaymentMethodMessagingPromotionsExperiment

    private let lock = NSLock()
    private var fetchState: FetchState
    private var fetchTask: Task<Void, Never>?

    init(elementsSession: STPElementsSession) {
        self.experiment = PaymentMethodMessagingPromotionsExperiment(elementsSession: elementsSession)
        self.fetchState = experiment.isInTreatment ? .idle : .completed([:])
    }

    init(
        experiment: PaymentMethodMessagingPromotionsExperiment,
        prefetchedPromotionContents: [String: PromotionContent]
    ) {
        self.experiment = experiment
        self.fetchState = .completed(prefetchedPromotionContents)
    }

    deinit {
        fetchTask?.cancel()
    }

    func prefetchIfNeeded(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) {
        guard experiment.isInTreatment else {
            setFetchState(.completed([:]))
            return
        }
        guard beginLoadingIfIdle() else {
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
            let contents = await Self.fetchPromotionContents(configuration: requestConfiguration)
            self?.completeLoading(with: contents)
        }
    }

    func shouldUsePaymentMethodMessagingRow(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        guard experiment.isInTreatment else {
            return false
        }
        return Self.paymentMethodIdentifier(for: paymentMethodType) != nil
    }

    func promotion(for paymentMethodType: PaymentSheet.PaymentMethodType) -> PromotionContent? {
        guard experiment.isInTreatment else {
            return nil
        }
        guard let identifier = Self.paymentMethodIdentifier(for: paymentMethodType) else {
            return nil
        }
        guard case .completed(let contentsByPaymentMethodType) = getFetchState() else {
            return nil
        }
        return contentsByPaymentMethodType[identifier]
    }

    func completeLoading(with contents: [String: PromotionContent]) {
        setFetchState(.completed(contents))
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
            guard Self.supportedPaymentMethodTypes.contains(stpPaymentMethodType) else {
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
        guard supportedPaymentMethodTypes.contains(stpPaymentMethodType) else {
            return nil
        }
        return stpPaymentMethodType.identifier
    }

    private static func fetchPromotionContents(
        configuration: PaymentMethodMessagingElement.Configuration
    ) async -> [String: PromotionContent] {
        do {
            let response = try await PaymentMethodMessagingElement.get(configuration: configuration)
            return response.paymentSheetPromotionContents()
        } catch {
            return [:]
        }
    }
}

extension PaymentMethodMessagingElement.APIResponse {
    func paymentSheetPromotionContents() -> [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] {
        var promotionContents: [String: PaymentMethodMessagingPromotionsHelper.PromotionContent] = [:]

        for paymentPlanGroup in paymentPlanGroups {
            let rawType = paymentPlanGroup.type
            let normalizedType = rawType.lowercased()

            guard PaymentMethodMessagingPromotionsHelper.supportedPaymentMethodIdentifiers.contains(normalizedType) else {
                stpAssertionFailure(
                    "Received unsupported payment_plan_groups.type '\(rawType)' while building PaymentSheet PMME promotions."
                )
                continue
            }

            guard let promotionContent = paymentPlanGroup.makePaymentSheetPromotionContent() else {
                stpAssertionFailure(
                    "Received invalid PMME payment_plan_group for PaymentSheet promotion type '\(rawType)'; required fields: summary.message, learn_more.message, learn_more.url."
                )
                continue
            }

            guard promotionContents[normalizedType] == nil else {
                stpAssertionFailure(
                    "Received duplicate payment_plan_groups.type '\(rawType)' while building PaymentSheet PMME promotions."
                )
                continue
            }

            promotionContents[normalizedType] = promotionContent
        }

        if !paymentPlanGroups.isEmpty && promotionContents.isEmpty {
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
