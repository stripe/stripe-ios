//
//  CustomerSheet+SwiftUI.swift
//  StripePaymentSheet
//
//

@_spi(STP) import StripeCore
import SwiftUI

extension View {
    /// Presents the customer sheet to select saved payment methods
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter customerSheet: A CustomerSheet to present.
    /// - Parameter onCompletion: Called with the result after the CustomerSheet is dismissed.
    public func customerSheet(
        isPresented: Binding<Bool>,
        customerSheet: CustomerSheet,
        onCompletion: @escaping (CustomerSheet.CustomerSheetResult) -> Void
    ) -> some View {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: SwiftUIProduct.self)
        return self.modifier(
            CustomerSheet.CustomerSheetPresentationModifier(
                isPresented: isPresented,
                customerSheet: customerSheet,
                onCompletion: onCompletion
            )
        )
    }
}

extension CustomerSheet {
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
                        presentSheet(on: viewController)
                    case (true, false):
                        guard let viewController = findViewController(for: view) else {
                            parent.presented = true
                            return
                        }
                        forciblyDismissSheet(from: viewController)
                    case (true, true):
                        break
                    }
                }
            }

            init(parent: CustomerSheetPresenter) {
                self.parent = parent
                self.presented = parent.presented
            }

            func presentSheet(on controller: UIViewController) {
                let presenter = findViewControllerPresenter(from: controller)

                parent.customerSheet?.present(from: presenter) { (result: CustomerSheet.CustomerSheetResult) in
                    self.parent.presented = false
                    self.parent.onCompletion(result)
                }
            }

            func forciblyDismissSheet(from controller: UIViewController) {
                if let bsvc = controller.presentedViewController as? BottomSheetViewController {
                    bsvc.didTapOrSwipeToDismiss()
                }
            }
        }
    }
}
