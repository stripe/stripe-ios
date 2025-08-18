//
//  PaymentSheet+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by David Estes on 1/14/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
//  This is adapted from a strategy used in BetterSafariView by Dongkyu Kim.
//  https://github.com/stleamist/BetterSafariView
//

@_spi(STP) import StripeCore
import SwiftUI

extension View {
    /// Presents a sheet for a customer to complete their payment.
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter paymentSheet: A PaymentSheet to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
    public func paymentSheet(
        isPresented: Binding<Bool>,
        paymentSheet: PaymentSheet,
        onCompletion: @escaping @MainActor (PaymentSheetResult) -> Void
    ) -> some View {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: SwiftUIProduct.self)
        return self.modifier(
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
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: SwiftUIProduct.self)
        return self.modifier(
            PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
                isPresented: isPresented,
                paymentSheetFlowController: paymentSheetFlowController,
                action: .presentPaymentOptions,
                optionsCompletion: onSheetDismissed,
                optionsCompletionWithResult: nil,
                paymentCompletion: nil
            )
        )
    }

    /// Presents a sheet for a customer to select a payment option.
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onSheetDismissed: Called after the payment options sheet is dismissed. The didCancel parameter is "true" if the user canceled the sheet (e.g. by tapping the close button or tapping outside the sheet), and "false" if they tapped the primary ("Continue") button.
    public func paymentOptionsSheet(
        isPresented: Binding<Bool>,
        paymentSheetFlowController: PaymentSheet.FlowController,
        onSheetDismissed: ((_ didCancel: Bool) -> Void)?
    ) -> some View {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: SwiftUIProduct.self)
        return self.modifier(
            PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
                isPresented: isPresented,
                paymentSheetFlowController: paymentSheetFlowController,
                action: .presentPaymentOptions,
                optionsCompletion: nil,
                optionsCompletionWithResult: onSheetDismissed,
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
        onCompletion: @escaping @MainActor (PaymentSheetResult) -> Void
    ) -> some View {
        self.modifier(
            PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
                isPresented: isConfirming,
                paymentSheetFlowController: paymentSheetFlowController,
                action: .confirm,
                optionsCompletion: nil,
                optionsCompletionWithResult: nil,
                paymentCompletion: onCompletion
            )
        )
    }

    /// :nodoc:
    @available(
        *, deprecated,
        renamed: "paymentConfirmationSheet(isConfirming:paymentSheetFlowController:onCompletion:)"
    )
    public func paymentConfirmationSheet(
        isConfirmingPayment: Binding<Bool>,
        paymentSheetFlowController: PaymentSheet.FlowController,
        onCompletion: @escaping @MainActor (PaymentSheetResult) -> Void
    ) -> some View {
        return paymentConfirmationSheet(
            isConfirming: isConfirmingPayment,
            paymentSheetFlowController: paymentSheetFlowController,
            onCompletion: onCompletion
        )
    }
}

extension PaymentSheet {
    /// A button which presents a sheet for a customer to complete their payment.
    /// This is a convenience wrapper for the .paymentSheet() ViewModifier.
    /// - Parameter paymentSheet: A PaymentSheet to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
    /// - Parameter content: The content of the view.
    public struct PaymentButton<Content: View>: View {
        private let paymentSheet: PaymentSheet
        private let onCompletion: @MainActor (PaymentSheetResult) -> Void
        private let content: Content

        @State private var showingPaymentSheet = false

        /// Initialize a `PaymentButton` with required parameters.
        public init(
            paymentSheet: PaymentSheet,
            onCompletion: @escaping @MainActor (PaymentSheetResult) -> Void,
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

extension PaymentSheet.FlowController {
    /// A button which presents a sheet for a customer to select a payment method.
    /// This is a convenience wrapper for the .paymentOptionsSheet() ViewModifier.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onSheetDismissed: Called after the payment method selector is dismissed.
    /// - Parameter content: The content of the view.
    public struct PaymentOptionsButton<Content: View>: View {
        private let paymentSheetFlowController: PaymentSheet.FlowController
        private let onSheetDismissed: (() -> Void)?
        private let onSheetDismissedWithResult: ((_ didCancel: Bool) -> Void)?
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
            self.onSheetDismissedWithResult = nil
            self.content = content()
        }

        /// A button which presents a sheet for a customer to select a payment method.
        /// This is a convenience wrapper for the .paymentOptionsSheet() ViewModifier.
        /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
        /// - Parameter onSheetDismissed: Called after the payment options sheet is dismissed. The didCancel parameter is "true" if the user canceled the sheet (e.g. by tapping the close button or tapping outside the sheet), and "false" if they tapped the primary ("Continue") button.
        /// - Parameter content: The content of the view.
        public init(
            paymentSheetFlowController: PaymentSheet.FlowController,
            onSheetDismissed: @escaping (_ didCancel: Bool) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSheetFlowController = paymentSheetFlowController
            self.onSheetDismissed = nil
            self.onSheetDismissedWithResult = onSheetDismissed
            self.content = content()
        }

        public var body: some View {
            Button(action: {
                showingPaymentSheet = true
            }) {
                content
            }
            .paymentOptionsSheet(
                isPresented: $showingPaymentSheet,
                paymentSheetFlowController: paymentSheetFlowController,
                onSheetDismissed: onSheetDismissedWithResult ?? { _ in onSheetDismissed?() }
            )
        }
    }

    /// :nodoc:
    @available(*, deprecated, renamed: "ConfirmButton")
    public typealias ConfirmPaymentButton = ConfirmButton

    /// A button which confirms the payment or setup. Depending on the user's payment method, it may present a confirmation sheet.
    /// This is a convenience wrapper for the .paymentConfirmationSheet() ViewModifier.
    /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
    /// - Parameter onCompletion: Called with the result of the payment/setup confirmation, after the PaymentSheet (if any) is dismissed.
    /// - Parameter content: The content of the view.
    public struct ConfirmButton<Content: View>: View {
        private let paymentSheetFlowController: PaymentSheet.FlowController
        private let onCompletion: @MainActor (PaymentSheetResult) -> Void
        private let content: Content

        @State private var showingPaymentSheet = false

        /// Initialize a `ConfirmPaymentButton` with required parameters.
        public init(
            paymentSheetFlowController: PaymentSheet.FlowController,
            onCompletion: @escaping @MainActor (PaymentSheetResult) -> Void,
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

extension PaymentSheet {
    struct PaymentSheetPresenter: UIViewRepresentable {
        @Binding var presented: Bool
        weak var paymentSheet: PaymentSheet?
        let onCompletion: @MainActor (PaymentSheetResult) -> Void

        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> UIView {
            return context.coordinator.view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.presented = presented
        }

        class Coordinator {

            var parent: PaymentSheetPresenter
            let view = UIView()
            var presented: Bool {
                didSet {
                    switch (oldValue, presented) {
                    case (false, false):
                        break
                    case (false, true):
                        guard let viewController = findViewController(for: view) else {
                            parent.presented = false
                            return
                        }
                        presentPaymentSheet(on: viewController)
                    case (true, false):
                        guard parent.paymentSheet?.bottomSheetViewController.presentingViewController != nil else {
                            // If PS is not presented, there's nothing to do
                            return
                        }
                        parent.paymentSheet?.bottomSheetViewController.didTapOrSwipeToDismiss()
                    case (true, true):
                        break
                    }
                }
            }

            init(parent: PaymentSheetPresenter) {
                self.parent = parent
                self.presented = parent.presented
            }

            func presentPaymentSheet(on controller: UIViewController) {
                let presenter = findViewControllerPresenter(from: controller)

                parent.paymentSheet?.present(from: presenter) { (result: PaymentSheetResult) in
                    self.parent.presented = false
                    Task { @MainActor in
                        self.parent.onCompletion(result)
                    }
                }
            }
        }
    }

    struct PaymentSheetFlowControllerPresenter: UIViewRepresentable {
        @Binding var presented: Bool
        weak var paymentSheetFlowController: PaymentSheet.FlowController?
        let action: FlowControllerAction
        let optionsCompletion: (() -> Void)?
        let optionsCompletionWithResult: ((_ didCancel: Bool) -> Void)?
        let paymentCompletion: (@MainActor (PaymentSheetResult) -> Void)?

        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        func makeUIView(context: Context) -> UIView {
            return context.coordinator.view
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.presented = presented
        }

        class Coordinator {
            var parent: PaymentSheetFlowControllerPresenter
            let view = UIView()

            var presented: Bool {
                didSet {
                    switch (oldValue, presented) {
                    case (false, false):
                        break
                    case (false, true):
                        guard let viewController = findViewController(for: view) else {
                            parent.presented = false
                            return
                        }
                        presentPaymentSheet(on: viewController)
                    case (true, false):
                        guard parent.paymentSheetFlowController?.viewController.presentingViewController != nil else {
                            // If PSFC is not presented, there's nothing to do
                            return
                        }
                        parent.paymentSheetFlowController?.viewController.didTapOrSwipeToDismiss()
                    case (true, true):
                        break
                    }
                }
            }

            init(parent: PaymentSheetFlowControllerPresenter) {
                self.parent = parent
                self.presented = parent.presented
            }

            func presentPaymentSheet(on controller: UIViewController) {
                let presenter = findViewControllerPresenter(from: controller)

                switch parent.action {
                case .confirm:
                    parent.paymentSheetFlowController?.confirm(from: presenter) { (result) in
                        self.parent.presented = false
                        Task { @MainActor in
                            self.parent.paymentCompletion?(result)
                        }
                    }
                case .presentPaymentOptions:
                    if let completionWithResult = parent.optionsCompletionWithResult {
                        parent.paymentSheetFlowController?.presentPaymentOptions(from: presenter) { didCancel in
                            self.parent.presented = false
                            completionWithResult(didCancel)
                        }
                    } else {
                        parent.paymentSheetFlowController?.presentPaymentOptions(from: presenter) {
                            self.parent.presented = false
                            self.parent.optionsCompletion?()
                        }
                    }
                }
            }
        }
    }

    struct PaymentSheetPresentationModifier: ViewModifier {
        @Binding var isPresented: Bool
        let paymentSheet: PaymentSheet
        let onCompletion: @MainActor (PaymentSheetResult) -> Void

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
        let optionsCompletionWithResult: ((_ didCancel: Bool) -> Void)?
        let paymentCompletion: ((PaymentSheetResult) -> Void)?

        func body(content: Content) -> some View {
            content.background(
                PaymentSheetFlowControllerPresenter(
                    presented: $isPresented,
                    paymentSheetFlowController: paymentSheetFlowController,
                    action: action,
                    optionsCompletion: optionsCompletion,
                    optionsCompletionWithResult: optionsCompletionWithResult,
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

func findViewController(for uiView: UIView) -> UIViewController? {
    if let nextResponder = uiView.next as? UIViewController {
        return nextResponder
    } else if let nextResponder = uiView.next as? UIView {
        return findViewController(for: nextResponder)
    } else {
        // Can't find a view, attempt to grab the top most view controller
        return topMostViewController()
    }
}

func topMostViewController() -> UIViewController? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return nil }

    var topController: UIViewController? = window.rootViewController

    // Traverse presented view controllers to find the top most view controller
    while let presentedViewController = topController?.presentedViewController {
        topController = presentedViewController
    }

    return topController
}

// Helper class to track SwiftUI usage
final class SwiftUIProduct: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "SwiftUI"
    }
}
