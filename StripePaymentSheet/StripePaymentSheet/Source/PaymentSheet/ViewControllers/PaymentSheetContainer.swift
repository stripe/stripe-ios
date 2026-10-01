//
//  PaymentSheetContainer.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
import UIKit

/// The presentation-independent interface used by PaymentSheet content.
/// Concrete containers own either the legacy bottom-sheet lifecycle or the native sheet lifecycle.
protocol PaymentSheetContainer: UIViewController, PaymentSheetAuthenticationContext {

    var appearance: PaymentSheet.Appearance { get }
    var isTestMode: Bool { get }
    var contentStack: [BottomSheetContentViewController] { get }
    var contentOffsetPercentage: CGFloat { get set }

    func setViewControllers(_ viewControllers: [BottomSheetContentViewController])
    func pushContentViewController(_ contentViewController: BottomSheetContentViewController)
    func popContentViewController(completion: (() -> Void)?) -> BottomSheetContentViewController?
    func setUserInteractionEnabled(_ enabled: Bool)

    func addBlurEffect(animated: Bool, backgroundColor: UIColor, completion: @escaping () -> Void)
    func removeBlurEffect(animated: Bool, completion: (() -> Void)?)
    func startSpinner()
    func transitionSpinnerToComplete(animated: Bool, completion: @escaping () -> Void)

    func invalidateContentDetent()
    func didTapOrSwipeToDismiss()
    func present(from presentingViewController: UIViewController, completion: (() -> Void)?)
}

extension PaymentSheetContainer {

    /// Legacy containers have no system detent to invalidate.
    func invalidateContentDetent() {}

    func popContentViewController() -> BottomSheetContentViewController? {
        popContentViewController(completion: nil)
    }

    func removeBlurEffect(animated: Bool) {
        removeBlurEffect(animated: animated, completion: nil)
    }

    func present(from presentingViewController: UIViewController) {
        present(from: presentingViewController, completion: nil)
    }
}

/// Selects a concrete container once, before any presentation lifecycle begins.
enum PaymentSheetContainerFactory {

    static func make(
        contentViewController: BottomSheetContentViewController,
        appearance: PaymentSheet.Appearance,
        isTestMode: Bool,
        usesNativeSheet: Bool = false,
        didCancelNative3DS2: @escaping () -> Void
    ) -> any PaymentSheetContainer {
        #if os(visionOS)
        let shouldUseNativeSheet = false
        #else
        let shouldUseNativeSheet = NativeSheetPresentation.isRequiredForDevice || usesNativeSheet
        #endif

        if shouldUseNativeSheet {
            return NativeSheetContainerViewController(
                contentViewController: contentViewController,
                appearance: appearance,
                isTestMode: isTestMode,
                didCancelNative3DS2: didCancelNative3DS2
            )
        }
        return BottomSheetViewController(
            contentViewController: contentViewController,
            appearance: appearance,
            isTestMode: isTestMode,
            didCancelNative3DS2: didCancelNative3DS2
        )
    }
}
