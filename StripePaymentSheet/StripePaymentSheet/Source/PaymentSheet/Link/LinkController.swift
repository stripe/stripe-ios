//
//  LinkController.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 6/19/25.
//

import UIKit

public class LinkController {

    private(set) public var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?

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
                let result = try await PaymentSheetLoader.load(
                    mode: .deferredIntent(intentConfiguration),
                    configuration: configuration,
                    analyticsHelper: analyticsHelper,
                    integrationShape: .complete
                )

                await presentingViewController.presentNativeLink(
                    selectedPaymentDetailsID: nil,
                    configuration: configuration,
                    intent: result.intent,
                    elementsSession: result.elementsSession,
                    analyticsHelper: analyticsHelper
                ) { [weak self] confirmOption, _ in
                    guard let confirmOption else {
                        self?.paymentOption = nil
                        callback()
                        return
                    }

                    let paymentOption: PaymentOption = .link(option: confirmOption)
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
