//
//  CustomerSheet+SwiftUI.swift
//  StripePaymentSheet
//
//

import SwiftUI

@_spi(PrivateBetaCustomerSheet) extension View {
    /// Presents a sheet for a customer to complete their payment.
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter paymentSheet: A PaymentSheet to present.
    /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
    public func customerSheet(
        isPresented: Binding<Bool>,
        customerSheet: CustomerSheet,
        onCompletion: @escaping (CustomerSheet.CustomerSheetResult) -> Void
    ) -> some View {
        self.modifier(
            CustomerSheet.CustomerSheetPresentationModifier(
                isPresented: isPresented,
                customerSheet: customerSheet,
                onCompletion: onCompletion
            )
        )
    }

}

@_spi(PrivateBetaCustomerSheet) extension CustomerSheet {
    /// A button which presents a sheet for a customer to complete their payment.
    /// This is a convenience wrapper for the .customerSheet() ViewModifier.
    /// - Parameter customerSheet: A CustomerSheet to present.
    /// - Parameter onCompletion: Called with the result of the selectedPaymentMethod after the customer sheet is dismissed.
    /// - Parameter content: The content of the view.
    public struct CustomerSheetButton<Content: View>: View {
        private let customerSheet: CustomerSheet
        private let onCompletion: (CustomerSheet.CustomerSheetResult) -> Void
        private let content: Content

        @State private var showingCustomerSheet = false

        /// Initialize a `CustomerSheetButton` with required parameters.
        public init(
            customerSheet: CustomerSheet,
            onCompletion: @escaping (CustomerSheet.CustomerSheetResult) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.customerSheet = customerSheet
            self.onCompletion = onCompletion
            self.content = content()
        }

        public var body: some View {
            Button(action: {
                showingCustomerSheet = true
            }) {
                content
            }.customerSheet(
                isPresented: $showingCustomerSheet,
                customerSheet: customerSheet,
                onCompletion: onCompletion)
        }
    }

    struct CustomerSheetPresentationModifier: ViewModifier {
        @Binding var isPresented: Bool
        let customerSheet: CustomerSheet
        let onCompletion: (CustomerSheet.CustomerSheetResult) -> Void

        func body(content: Content) -> some View {
            content.background(
                CustomerSheetPresenter(
                    presented: $isPresented,
                    customerSheet: customerSheet,
                    onCompletion: onCompletion
                )
            )
        }
    }

    struct CustomerSheetPresenter: UIViewRepresentable {
        @Binding var presented: Bool
        weak var customerSheet: CustomerSheet?
        let onCompletion: (CustomerSheet.CustomerSheetResult) -> Void

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

            var parent: CustomerSheetPresenter
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
                        guard let viewController = findViewController(for: view) else {
                            parent.presented = true
                            return
                        }
                        forciblyDismissPaymentSheet(from: viewController)
                    case (true, true):
                        break
                    }
                }
            }

            init(parent: CustomerSheetPresenter) {
                self.parent = parent
                self.presented = parent.presented
            }

            func presentPaymentSheet(on controller: UIViewController) {
                let presenter = findViewControllerPresenter(from: controller)

                parent.customerSheet?.present(from: presenter) { (result: CustomerSheet.CustomerSheetResult) in
                    self.parent.presented = false
                    self.parent.onCompletion(result)
                }
            }

            func forciblyDismissPaymentSheet(from controller: UIViewController) {
                if let bsvc = controller.presentedViewController as? BottomSheetViewController {
                    bsvc.didTapOrSwipeToDismiss()
                }
            }
        }
    }
}



