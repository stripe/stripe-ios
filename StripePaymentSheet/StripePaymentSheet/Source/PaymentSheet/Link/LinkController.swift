//
//  LinkController.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import Combine
import UIKit

public class LinkController: ObservableObject {
    private var internalPaymentOption: PaymentOption?
    @Published public private(set) var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?
    private var loadResult: PaymentSheetLoader.LoadResult?

    public func present(
        from presentingViewController: UIViewController,
        with email: String?,
        callback: @escaping () -> Void
    ) {
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
                var result = loadResult

                if result == nil {
                    result = try await PaymentSheetLoader.load(
                        mode: .deferredIntent(intentConfiguration),
                        configuration: configuration,
                        analyticsHelper: analyticsHelper,
                        integrationShape: .complete
                    )
                }

                self.loadResult = result

                var selectedPaymentDetailsID: String?

                if case .link(let confirmOption) = internalPaymentOption {
                    if case .withPaymentDetails(_, let paymentDetails, _, _) = confirmOption {
                        selectedPaymentDetailsID = paymentDetails.stripeID
                    }
                }

                await presentingViewController.presentNativeLink(
                    selectedPaymentDetailsID: selectedPaymentDetailsID,
                    configuration: configuration,
                    intent: loadResult!.intent,
                    elementsSession: loadResult!.elementsSession,
                    analyticsHelper: analyticsHelper
                ) { [weak self] confirmOption, _ in
                    guard let confirmOption else {
                        self?.paymentOption = nil
                        self?.internalPaymentOption = nil
                        callback()
                        return
                    }

                    let paymentOption: PaymentOption = .link(option: confirmOption)
                    self?.internalPaymentOption = paymentOption
                    self?.paymentOption = .init(paymentOption: paymentOption, currency: nil, iconStyle: .filled)
                    callback()
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    public static func create() -> LinkController {
        return LinkController()
    }
}
