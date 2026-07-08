//
//  CustomerSheet+SwiftUI.swift
//  StripePaymentSheet
//
//

@_spi(STP) import StripeCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
private typealias CustomerSheetPlatformViewRepresentable = UIViewRepresentable
#elseif canImport(AppKit)
private typealias CustomerSheetPlatformViewRepresentable = NSViewRepresentable
#endif

extension View {
    /// Presents the customer sheet to select saved payment methods
    /// - Parameter isPresented: A binding to whether the sheet is presented.
    /// - Parameter customerSheet: A CustomerSheet to present.
    /// - Parameter onCompletion: Called with the result after the CustomerSheet is dismissed.
    public func customerSheet(
        isPresented: Binding<Bool>,
        customerSheet: CustomerSheet,
        onCompletion: @escaping @MainActor (CustomerSheet.CustomerSheetResult) -> Void
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
        let onCompletion: @MainActor (CustomerSheet.CustomerSheetResult) -> Void

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

    struct CustomerSheetPresenter: CustomerSheetPlatformViewRepresentable {
        @Binding var presented: Bool
        weak var customerSheet: CustomerSheet?
        let onCompletion: @MainActor (CustomerSheet.CustomerSheetResult) -> Void

        func makeCoordinator() -> Coordinator {
            return Coordinator(parent: self)
        }

        private func makeView(context: Context) -> UIView {
            return context.coordinator.view
        }

        private func updateView(_ view: UIView, context: Context) {
            context.coordinator.parent = self
            context.coordinator.presented = presented
        }

        #if canImport(UIKit)
        func makeUIView(context: Context) -> UIView {
            makeView(context: context)
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            updateView(uiView, context: context)
        }
        #elseif canImport(AppKit)
        func makeNSView(context: Context) -> UIView {
            makeView(context: context)
        }

        func updateNSView(_ nsView: UIView, context: Context) {
            updateView(nsView, context: context)
        }
        #endif

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

                parent.customerSheet?.present(from: presenter, completion: { result in
                    Task { @MainActor in
                        self.parent.presented = false
                        self.parent.onCompletion(result)
                    }
                }, onDismiss: {
                    Task { @MainActor in
                        self.parent.presented = false
                    }
                })
            }

            func forciblyDismissSheet(from controller: UIViewController) {
                if let bsvc = controller.presentedViewController as? BottomSheetViewController {
                    bsvc.didTapOrSwipeToDismiss()
                }
            }
        }
    }
}
