import UIKit

/// Owns presentation when an SDK surface composes the element into a larger checkout.
@MainActor
protocol EmbeddedPaymentElementUIHost: AnyObject {
    var isPresentingPaymentUI: Bool { get }
    func presentPaymentUI(_ viewController: BottomSheetViewController)
    func dismissPaymentUI(completion: (() -> Void)?)
}

extension EmbeddedPaymentElement {
    func presentPaymentUI(_ viewController: BottomSheetViewController) {
        if let paymentUIHost {
            paymentUIHost.presentPaymentUI(viewController)
        } else {
            resolvedPresentingViewController?.presentAsBottomSheet(viewController, appearance: configuration.appearance)
        }
    }

    func dismissPaymentUI(from viewController: UIViewController? = nil, completion: (() -> Void)? = nil) {
        if let paymentUIHost {
            paymentUIHost.dismissPaymentUI(completion: completion)
        } else {
            (viewController ?? presentingViewController)?.dismiss(animated: true, completion: completion)
        }
    }
}
