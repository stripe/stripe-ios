//
//  STPPaymentConfirmation+SwiftUI.swift
//  StripeiOS
//
//  Created by David Estes on 2/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import SwiftUI
import SafariServices

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
struct ConfirmPaymentPresenter<ParamsType, CompletionBlockType>: UIViewControllerRepresentable {
    @Binding var presented: Bool
    let intentParams: ParamsType
    let onCompletion: CompletionBlockType

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return context.coordinator.uiViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.presented = presented
    }

    class Coordinator: NSObject, STPAuthenticationContext {
        func authenticationPresentingViewController() -> UIViewController {
            // This is a bit of a hack: We traverse the view hierarchy looking for the most reasonable VC to present from.
            // A VC hosted within a SwiftUI cell, for example, doesn't have a parent, so we need to find the UIWindow.
            var presentingViewController = uiViewController.view.window?.rootViewController
            presentingViewController =
                presentingViewController?.presentedViewController ?? presentingViewController
                ?? uiViewController
            return presentingViewController ?? UIViewController()
        }

        var parent: ConfirmPaymentPresenter
        init(parent: ConfirmPaymentPresenter) {
            self.parent = parent
        }

        let uiViewController = UIViewController()

        var presented: Bool = false {
            didSet {
                if oldValue != presented {
                    presented ? presentConfirmationSheet() : forciblyDismissConfirmationSheet()
                }
            }
        }

        private func presentConfirmationSheet() {
            if let params = self.parent.intentParams as? STPPaymentIntentParams,
                let completion = self.parent.onCompletion
                    as? STPPaymentHandlerActionPaymentIntentCompletionBlock
            {
                STPPaymentHandler.sharedHandler.confirmPayment(params, with: self) {
                    (status, pi, error) in
                    self.parent.presented = false
                    completion(status, pi, error)
                }
            } else if let params = self.parent.intentParams as? STPSetupIntentConfirmParams,
                let completion = self.parent.onCompletion
                    as? STPPaymentHandlerActionSetupIntentCompletionBlock
            {
                STPPaymentHandler.sharedHandler.confirmSetupIntent(params, with: self) {
                    (status, si, error) in
                    self.parent.presented = false
                    completion(status, si, error)
                }
            } else {
                assert(false, "ConfirmPaymentPresenter was passed an invalid type.")
            }

        }

        private func forciblyDismissConfirmationSheet() {
            if let sfvc = self.authenticationPresentingViewController().presentedViewController as? SFSafariViewController,
               !sfvc.isBeingDismissed
            {
                self.authenticationPresentingViewController().dismiss(animated: true)
            }
        }
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension View {
    /// Confirm the payment, presenting a sheet for the user to confirm their payment if needed.
    /// - Parameter isConfirmingPayment: A binding to whether the payment is being confirmed. This will present a sheet if needed. It will be updated to `false` after performing the payment confirmation.
    /// - Parameter paymentIntentParams: A PaymentIntentParams to confirm.
    /// - Parameter onCompletion: Called with the result of the payment after the payment confirmation is done and the sheet (if any) is dismissed.
    public func paymentConfirmationSheet(
        isConfirmingPayment: Binding<Bool>,
        paymentIntentParams: STPPaymentIntentParams,
        onCompletion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) -> some View {
        self.modifier(
            ConfirmPaymentPresentationModifier(
                isPresented: isConfirmingPayment,
                intentParams: paymentIntentParams,
                onCompletion: onCompletion
            )
        )
    }

    /// Confirm the SetupIntent, presenting a sheet for the user to confirm if needed.
    /// - Parameter isConfirmingSetupIntent: A binding to whether the SetupIntent is being confirmed. This will present a sheet if needed. It will be updated to `false` after performing the SetupIntent confirmation.
    /// - Parameter paymentIntentParams: A SetupIntentParams to confirm.
    /// - Parameter onCompletion: Called with the result of the SetupIntent confirmation after the confirmation is done and the sheet (if any) is dismissed.
    public func setupIntentConfirmationSheet(
        isConfirmingSetupIntent: Binding<Bool>,
        setupIntentParams: STPSetupIntentConfirmParams,
        onCompletion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) -> some View {
        self.modifier(
            ConfirmPaymentPresentationModifier(
                isPresented: isConfirmingSetupIntent,
                intentParams: setupIntentParams,
                onCompletion: onCompletion
            )
        )
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
struct ConfirmPaymentPresentationModifier<ParamsType, CompletionBlockType>: ViewModifier {
    @Binding var isPresented: Bool
    let intentParams: ParamsType
    let onCompletion: CompletionBlockType

    func body(content: Content) -> some View {
        content.background(
            ConfirmPaymentPresenter(
                presented: $isPresented,
                intentParams: intentParams,
                onCompletion: onCompletion
            )
        )
    }
}
