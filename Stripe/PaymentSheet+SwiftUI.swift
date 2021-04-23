//
//  PaymentSheet+SwiftUI.swift
//  StripeiOS
//
//  Created by David Estes on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
//  This is adapted from a strategy used in BetterSafariView by Dongkyu Kim.
//  https://github.com/stleamist/BetterSafariView

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension View {
    /// Presents a sheet for a customer to complete their payment.
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter paymentSheet: A PaymentSheet to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
    public func paymentSheet(
        isPresented: Binding<Bool>,
        paymentSheet: PaymentSheet,
        onCompletion: @escaping (PaymentSheetResult) -> Void
    ) -> some View {
        self.modifier(
            PaymentSheet.PaymentSheetPresentationModifier(
                isPresented: isPresented,
                paymentSheet: paymentSheet,
                onCompletion: onCompletion
            )
        )
    }

    /// Presents a sheet for a customer to select a payment option.
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onSheetDismissed: Called after the payment options sheet is dismissed.
    public func paymentOptionsSheet(
        isPresented: Binding<Bool>,
        paymentSheetFlowController: PaymentSheet.FlowController,
        onSheetDismissed: (() -> Void)?
    ) -> some View {
        self.modifier(
            PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
                isPresented: isPresented,
                paymentSheetFlowController: paymentSheetFlowController,
                action: .presentPaymentOptions,
                optionsCompletion: onSheetDismissed,
                paymentCompletion: nil
            )
        )
    }

    /// Confirm the payment, presenting a sheet for the user to confirm their payment if needed.
    /// - Parameter isConfirming: A binding to whether the payment is being confirmed. This will present a sheet if needed. It will be updated to `false` after performing the payment confirmation.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment confirmation is done and the sheet (if any) is dismissed.
    public func paymentConfirmationSheet(
        isConfirming: Binding<Bool>,
        paymentSheetFlowController: PaymentSheet.FlowController,
        onCompletion: @escaping (PaymentSheetResult) -> Void
    ) -> some View {
        self.modifier(
            PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
                isPresented: isConfirming,
                paymentSheetFlowController: paymentSheetFlowController,
                action: .confirm,
                optionsCompletion: nil,
                paymentCompletion: onCompletion
            )
        )
    }

    @available(
        *, deprecated,
        renamed: "paymentConfirmationSheet(isConfirming:paymentSheetFlowController:onCompletion:)"
    )
    public func paymentConfirmationSheet(
        isConfirmingPayment: Binding<Bool>,
        paymentSheetFlowController: PaymentSheet.FlowController,
        onCompletion: @escaping (PaymentSheetResult) -> Void
    ) -> some View {
        return paymentConfirmationSheet(
            isConfirming: isConfirmingPayment,
            paymentSheetFlowController: paymentSheetFlowController,
            onCompletion: onCompletion
        )
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    /// A button which presents a sheet for a customer to complete their payment.
    /// This is a convenience wrapper for the .paymentSheet() ViewModifier.
    /// - Parameter paymentSheet: A PaymentSheet to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
    /// - Parameter content: The content of the view.
    public struct PaymentButton<Content: View>: View {
        private let paymentSheet: PaymentSheet
        private let onCompletion: (PaymentSheetResult) -> Void
        private let content: Content

        @State private var showingPaymentSheet = false

        /// Initialize a `PaymentButton` with required parameters.
        public init(
            paymentSheet: PaymentSheet,
            onCompletion: @escaping (PaymentSheetResult) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSheet = paymentSheet
            self.onCompletion = onCompletion
            self.content = content()
        }

        public var body: some View {
            Button(action: {
                showingPaymentSheet = true
            }) {
                content
            }.paymentSheet(
                isPresented: $showingPaymentSheet,
                paymentSheet: paymentSheet,
                onCompletion: onCompletion)
        }
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet.FlowController {
    /// A button which presents a sheet for a customer to select a payment method.
    /// This is a convenience wrapper for the .paymentOptionsSheet() ViewModifier.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onSheetDismissed: Called after the payment method selector is dismissed.
    /// - Parameter content: The content of the view.
    public struct PaymentOptionsButton<Content: View>: View {
        private let paymentSheetFlowController: PaymentSheet.FlowController
        private let onSheetDismissed: () -> Void
        private let content: Content

        @State private var showingPaymentSheet = false

        /// Initialize a `PaymentOptionsButton` with required parameters.
        public init(
            paymentSheetFlowController: PaymentSheet.FlowController,
            onSheetDismissed: @escaping () -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSheetFlowController = paymentSheetFlowController
            self.onSheetDismissed = onSheetDismissed
            self.content = content()
        }

        public var body: some View {
            Button(action: {
                showingPaymentSheet = true
            }) {
                content
            }.paymentOptionsSheet(
                isPresented: $showingPaymentSheet,
                paymentSheetFlowController: paymentSheetFlowController,
                onSheetDismissed: onSheetDismissed)
        }
    }

    @available(*, deprecated, renamed: "ConfirmButton")
    public typealias ConfirmPaymentButton = ConfirmButton

    /// A button which confirms the payment or setup. Depending on the user's payment method, it may present a confirmation sheet.
    /// This is a convenience wrapper for the .paymentConfirmationSheet() ViewModifier.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onCompletion: Called with the result of the payment/setup confirmation, after the PaymentSheet (if any) is dismissed.
    /// - Parameter content: The content of the view.
    public struct ConfirmButton<Content: View>: View {
        private let paymentSheetFlowController: PaymentSheet.FlowController
        private let onCompletion: (PaymentSheetResult) -> Void
        private let content: Content

        @State private var showingPaymentSheet = false

        /// Initialize a `ConfirmPaymentButton` with required parameters.
        public init(
            paymentSheetFlowController: PaymentSheet.FlowController,
            onCompletion: @escaping (PaymentSheetResult) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSheetFlowController = paymentSheetFlowController
            self.onCompletion = onCompletion
            self.content = content()
        }

        public var body: some View {
            Button(action: {
                showingPaymentSheet = true
            }) {
                content
            }.paymentConfirmationSheet(
                isConfirming: $showingPaymentSheet,
                paymentSheetFlowController: paymentSheetFlowController,
                onCompletion: onCompletion)
        }
    }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
    struct PaymentSheetPresenter: UIViewControllerRepresentable {
        @Binding var presented: Bool
        let paymentSheet: PaymentSheet
        let onCompletion: (PaymentSheetResult) -> Void

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

        class Coordinator: NSObject {
            var parent: PaymentSheetPresenter
            init(parent: PaymentSheetPresenter) {
                self.parent = parent
            }

            let uiViewController = UIViewController()

            var presented: Bool = false {
                didSet {
                    if oldValue != presented {
                        presented ? presentPaymentSheet() : forciblyDismissPaymentSheet()
                    }
                }
            }

            private func presentPaymentSheet() {
                let paymentSheet = parent.paymentSheet


                paymentSheet.present(from: findViewControllerPresenter(from: uiViewController)) {
                    (result: PaymentSheetResult) in
                    self.parent.presented = false
                    self.parent.onCompletion(result)
                }
            }

            private func forciblyDismissPaymentSheet() {
                if let bsvc = uiViewController.presentedViewController as? BottomSheetViewController
                {
                    bsvc.didTapOrSwipeToDismiss()
                }
            }
        }
    }

    struct PaymentSheetFlowControllerPresenter: UIViewControllerRepresentable {
        @Binding var presented: Bool
        let paymentSheetFlowController: PaymentSheet.FlowController
        let action: FlowControllerAction
        let optionsCompletion: (() -> Void)?
        let paymentCompletion: ((PaymentSheetResult) -> Void)?

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

        class Coordinator: NSObject {
            var parent: PaymentSheetFlowControllerPresenter
            init(parent: PaymentSheetFlowControllerPresenter) {
                self.parent = parent
            }

            let uiViewController = UIViewController()

            var presented: Bool = false {
                didSet {
                    if oldValue != presented {
                        presented ? presentPaymentSheet() : forciblyDismissPaymentSheet()
                    }
                }
            }

            private func presentPaymentSheet() {
                let flowController = parent.paymentSheetFlowController
                let presenter = findViewControllerPresenter(from: uiViewController)

                switch parent.action {
                case .confirm:
                    flowController.confirm(from: presenter) { result in
                        self.parent.presented = false
                        self.parent.paymentCompletion!(result)
                    }
                case .presentPaymentOptions:
                    flowController.presentPaymentOptions(from: presenter) {
                        self.parent.presented = false
                        self.parent.optionsCompletion?()
                    }
                }
            }

            private func forciblyDismissPaymentSheet() {
                if let bsvc = uiViewController.presentedViewController as? BottomSheetViewController
                {
                    bsvc.didTapOrSwipeToDismiss()
                }
            }
        }
    }

    struct PaymentSheetPresentationModifier: ViewModifier {
        @Binding var isPresented: Bool
        let paymentSheet: PaymentSheet
        let onCompletion: (PaymentSheetResult) -> Void

        func body(content: Content) -> some View {
            content.background(
                PaymentSheetPresenter(
                    presented: $isPresented,
                    paymentSheet: paymentSheet,
                    onCompletion: onCompletion
                )
            )
        }
    }

    enum FlowControllerAction {
        case presentPaymentOptions
        case confirm
    }

    struct PaymentSheetFlowControllerPresentationModifier: ViewModifier {
        @Binding var isPresented: Bool
        let paymentSheetFlowController: PaymentSheet.FlowController
        let action: FlowControllerAction
        let optionsCompletion: (() -> Void)?
        let paymentCompletion: ((PaymentSheetResult) -> Void)?

        func body(content: Content) -> some View {
            content.background(
                PaymentSheetFlowControllerPresenter(
                    presented: $isPresented,
                    paymentSheetFlowController: paymentSheetFlowController,
                    action: action,
                    optionsCompletion: optionsCompletion,
                    paymentCompletion: paymentCompletion
                )
            )
        }
    }
}

// MARK: - Helper functions

func findViewControllerPresenter(from uiViewController: UIViewController) -> UIViewController {
    // Note: creating a UIViewController inside here results in a nil window

    // This is a bit of a hack: We traverse the view hierarchy looking for the most reasonable VC to present from.
    // A VC hosted within a SwiftUI cell, for example, doesn't have a parent, so we need to find the UIWindow.
    var presentingViewController: UIViewController =
        uiViewController.view.window?.rootViewController ?? uiViewController

    // Find the most-presented UIViewController
    while let presented = presentingViewController.presentedViewController {
        presentingViewController = presented
    }

    return presentingViewController
}
