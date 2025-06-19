//
//  LinkController.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import Combine
import UIKit

@_spi(STP) import StripePayments

public class LinkController: ObservableObject {
    private var internalPaymentOption: PaymentOption?
    @Published public private(set) var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?

    private var loadResult: PaymentSheetLoader.LoadResult?
    private var session: ConsumerSession?

    public var isExistingLinkConsumer: Bool {
        session != nil
    }

    public func lookupConsumer(with email: String, completion: @escaping () -> Void) {
        let intentConfiguration = PaymentSheet.IntentConfiguration(
            mode: .setup(
                currency: nil,
                setupFutureUsage: .offSession
            ),
            confirmHandler: { _, _, intentCreationCallback in
                intentCreationCallback(.success(PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT))
            }
        )

        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = email
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration)

        Task {
            do {
                let result = try await PaymentSheetLoader.load(
                    mode: .deferredIntent(intentConfiguration),
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    integrationShape: .complete
                )

                self.loadResult = result

                let linkAccount = LinkAccountContext.shared.account
                self.session = linkAccount?.currentSession
                completion()
            } catch {
                print(error)
                completion()
            }
        }
    }

    public func present(
        from presentingViewController: UIViewController,
        with email: String?,
        callback: @escaping () -> Void
    ) {
        var selectedPaymentDetailsID: String?

        if case .link(let confirmOption) = internalPaymentOption {
            if case .withPaymentDetails(_, let paymentDetails, _, _) = confirmOption {
                selectedPaymentDetailsID = paymentDetails.stripeID
            }
        }

        var configuration = PaymentSheet.Configuration()
        configuration.defaultBillingDetails.email = email
        let analyticsHelper = PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration)

        presentingViewController.presentNativeLink(
            selectedPaymentDetailsID: selectedPaymentDetailsID,
            configuration: configuration,
            intent: loadResult!.intent,
            elementsSession: loadResult!.elementsSession,
            analyticsHelper: analyticsHelper
        ) { [weak self] confirmOption, shouldClearSelection in
            guard let confirmOption else {
                if shouldClearSelection {
                    self?.paymentOption = nil
                    self?.internalPaymentOption = nil
                }
                callback()
                return
            }

            let paymentOption: PaymentOption = .link(option: confirmOption)
            self?.internalPaymentOption = paymentOption
            self?.paymentOption = .init(paymentOption: paymentOption, currency: nil, iconStyle: .filled)
            callback()
        }
    }

    public func createPaymentMethod(completion: @escaping (Result<STPPaymentMethod, Error>) -> Void) {
        guard let paymentDetailsID = internalPaymentOption?.currentLinkPaymentMethod else {
            return
        }

        guard let consumerSessionClientSecret = LinkAccountContext.shared.account?.currentSession?.clientSecret else {
            return
        }

        let apiClient = STPAPIClient.shared

        apiClient.sharePaymentDetails(
            for: consumerSessionClientSecret,
            id: paymentDetailsID,
            consumerAccountPublishableKey: nil,
            allowRedisplay: .unspecified,
            cvc: nil,
            expectedPaymentMethodType: nil,
            billingPhoneNumber: nil
        ) { shareResult in
            switch shareResult {
            case .success(let success):
                completion(.success(success.paymentMethod))
            case .failure(let failure):
                completion(.failure(failure))
            }
        }
    }

    public static func create() -> LinkController {
        return LinkController()
    }
}
