//
//  LinkBankPaymentController.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/6/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// `LinkPaymentController` encapsulates the Link payment flow, allowing you to let your customers pay with their Link account.
/// This feature is currently invite-only. To accept payments, [use the Mobile Payment Element.](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(LinkOnly) public class LinkBankPaymentController {

    private let clientSecret: String
    private var returnURL: String?
    private var presentationCompletion: ((Result<Void, Swift.Error>) -> Void)?
    private let configuration: PaymentSheet.Configuration

    /// The parent view controller to present
    private lazy var bottomSheetViewController: BottomSheetViewController = {
        let isTestMode = apiClient.isTestmode
        let loadingViewController = LoadingViewController(
            delegate: self,
            appearance: PaymentSheet.Appearance.default,
            isTestMode: isTestMode,
            loadingViewHeight: 244
        )

        let vc = BottomSheetViewController(
            contentViewController: loadingViewController,
            appearance: PaymentSheet.Appearance.default,
            isTestMode: isTestMode,
            didCancelNative3DS2: {}
        )
        return vc
    }()

    /// The APIClient instance used to make requests to Stripe
    @_spi(LinkOnly) public var apiClient: STPAPIClient = STPAPIClient.shared


    /// Initializes a new `LinkPaymentController` instance.
    /// - Parameter paymentIntentClientSecret: The [client secret](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-client_secret) of a Stripe PaymentIntent object
    /// - Note: This can be used to complete a payment - don't log it, store it, or expose it to anyone other than the customer.
    /// - Parameter returnURL: A URL that redirects back to your app for flows that complete authentication in another app (such as a bank app).
    /// - Parameter billingDetails: Any information about the customer you've already collected.
    @_spi(LinkOnly) public init(paymentIntentClientSecret: String, configuration: PaymentSheet.Configuration, returnURL: String? = nil) {
        self.clientSecret = paymentIntentClientSecret
        self.configuration = configuration
        self.returnURL = returnURL
    }


    /// Presents the Link payment flow, allowing your customer to pay with Link.
    /// The flow lets your customer log into or create a Link account, select a valid source of funds, and approve the usage of those funds to complete the purchase. The actual purchase will not occur until you call `confirm(from:completion:)`.
    /// - Note: Once `confirm(from:completion:)` completes successfully (i.e. when `result` is `.success`), calling this method is an error, as payment/setup intents should not be reused. Until then, you may call this method as many times as is necessary.
    /// - Parameter presentingViewController: The view controller to present the payment flow from.
    /// - Parameter completion: Called when the payment flow is dismissed. If the flow was completed successfully, the result will be `.success`, and you can call `confirm(from:completion:)` when you're ready to complete the payment. If it was not, the result will be `.failure` with an `Error` describing what happened; this will be `LinkPaymentController.Error.canceled` if the customer canceled the flow.
    @_spi(LinkOnly)
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        // Overwrite completion closure to retain self until called
        let presentationCompletion: (Result<Void, Swift.Error>) -> Void = { result in
        
            // Dismiss if necessary
            if let presentingViewController = self.bottomSheetViewController.presentingViewController {
                // Calling `dismiss()` on the presenting view controller causes
                // the bottom sheet and any presented view controller by
                // bottom sheet (i.e. Link) to be dismissed all at the same time.
                presentingViewController.dismiss(animated: true) {
                    completion(result)
                }
            } else {
                completion(result)
            }
            self.presentationCompletion = nil
        }
        self.presentationCompletion = presentationCompletion

        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = PaymentSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failure(error))
            return
        }

        presentingViewController.presentAsBottomSheet(bottomSheetViewController, appearance: PaymentSheet.Appearance.default)
        
        apiClient.generateInstantDebitsOnlyHostedFlowURLForPaymentIntent(paymentIntentClientSecret: clientSecret, returnURL: "stripe-auth://redirect").observe { result in
            switch result {
            case .success(let url):
                guard var urlString = url else {
                    // error out
                    return
                }
                if let range = urlString.range(of: "auth.link.com") {
                    urlString.replaceSubrange(range, with: "vardges-bankcon-auth-srv.tunnel.stripe.me")
                }
                let hostedURL = URL(string: urlString)!
                print(urlString)
                let instantDebitsController = InstantDebitsOnlyViewController(apiClient: self.apiClient, clientSecret: self.clientSecret, hostedURL: hostedURL, configuration: self.configuration)
                self.bottomSheetViewController.contentStack = [instantDebitsController]
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    /// Completes the Link payment or setup.
    /// - Note: Once `completion` is called with a `.completed` result, this `LinkPaymentController` instance should no longer be used, as payment/setup intents should not be reused. Other results indicate cancellation or failure, and do not invalidate the instance.
    /// - Parameter presentingViewController: The view controller used to present any view controllers required e.g. to authenticate the customer
    /// - Parameter completion: Called with the result of the payment after any presented view controllers are dismissed
    @_spi(LinkOnly) public func confirm(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> Void) {
        guard let instantDebitsController = self.bottomSheetViewController.contentStack.last as? InstantDebitsOnlyViewController else {
            return
        }

        instantDebitsController.confirmIntent()
    }


    /// Errors related to the Link payment flow
    ///
    /// Most errors do not originate from LinkPaymentController itself; instead, they come from the Stripe API or other SDK components
    @frozen @_spi(LinkOnly) public enum Error: Swift.Error {
        /// The customer canceled the flow they were in.
        case canceled
        /// Link is unavailable at this time.
        case unavailable
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
@_spi(LinkOnly)
extension LinkBankPaymentController: LoadingViewControllerDelegate {
    func shouldDismiss(_ loadingViewController: LoadingViewController) {
        loadingViewController.dismiss(animated: true) {
            self.presentationCompletion?(.failure(LinkBankPaymentController.Error.canceled))
        }
    }

}
