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
  func paymentSheet(
    isPresented: Binding<Bool>,
    paymentSheet: PaymentSheet,
    onCompletion: @escaping (PaymentResult) -> Void
  ) -> some View {
    self.modifier(
      PaymentSheet.PaymentSheetPresentationModifier(
        isPresented: isPresented,
        paymentSheet: paymentSheet,
        completion: onCompletion
      )
    )
  }

  /// Presents a sheet for a customer to select a payment option.
  /// - Parameter isPresented: A binding to whether the sheet is presented.
  /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
  /// - Parameter onCompletion: Called after the payment options sheet is dismissed.
  func paymentOptionsSheet(
    isPresented: Binding<Bool>,
    paymentSheetFlowController: PaymentSheet.FlowController,
    onCompletion: (() -> Void)?
  ) -> some View {
    self.modifier(
      PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
        isPresented: isPresented,
        paymentSheetFlowController: paymentSheetFlowController,
        action: .presentPaymentOptions,
        optionsCompletion: onCompletion,
        paymentCompletion: nil
      )
    )
  }

  /// Confirm the payment, presenting a sheet for the user to confirm their payment if needed.
  /// - Parameter isPresented: A binding to whether the sheet is presented.
  /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
  /// - Parameter onCompletion: Called with the result of the payment after the payment sheet is dismissed.
  func paymentConfirmationSheet(
    isPresented: Binding<Bool>,
    paymentSheetFlowController: PaymentSheet.FlowController,
    onCompletion: @escaping (PaymentResult) -> Void
  ) -> some View {
    self.modifier(
      PaymentSheet.PaymentSheetFlowControllerPresentationModifier(
        isPresented: isPresented,
        paymentSheetFlowController: paymentSheetFlowController,
        action: .confirmPayment,
        optionsCompletion: nil,
        paymentCompletion: onCompletion
      )
    )
  }
}

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension PaymentSheet {
  /// A button which presents a sheet for a customer to complete their payment.
  /// - Parameter paymentSheet: A PaymentSheet to present.
  /// - Parameter onCompletion: Called with the result of the payment after the PaymentSheet is dismissed.
  /// - Parameter content: The content of the view.
  public struct PaymentButton<Content: View>: View {
    private let paymentSheet: PaymentSheet
    private let onCompletion: (PaymentResult) -> Void
    private let content: Content

    @State private var showingPaymentSheet = false

    /// Initialize a `PaymentButton` with required parameters.
    public init(
      paymentSheet: PaymentSheet,
      onCompletion: @escaping (PaymentResult) -> Void,
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
  /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
  /// - Parameter onCompletion: Called after the PaymentSheet is dismissed.
  /// - Parameter content: The content of the view.
  public struct PaymentOptionsButton<Content: View>: View {
    private let paymentSheetFlowController: PaymentSheet.FlowController
    private let onCompletion: () -> Void
    private let content: Content

    @State private var showingPaymentSheet = false

    /// Initialize a `PaymentOptionsButton` with required parameters.
    public init(
      paymentSheetFlowController: PaymentSheet.FlowController,
      onCompletion: @escaping () -> Void,
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
      }.paymentOptionsSheet(
        isPresented: $showingPaymentSheet,
        paymentSheetFlowController: paymentSheetFlowController,
        onCompletion: onCompletion)
    }
  }

  /// A button which confirms the payment. Depending on the user's payment method, it may present a confirmation sheet.
  /// - Parameter paymentSheetFlowController: A PaymentSheet.FlowController to present.
  /// - Parameter onCompletion: Called with the result of the payment after the PaymentSheet is dismissed.
  /// - Parameter content: The content of the view.
  public struct ConfirmPaymentButton<Content: View>: View {
    private let paymentSheetFlowController: PaymentSheet.FlowController
    private let onCompletion: (PaymentResult) -> Void
    private let content: Content

    @State private var showingPaymentSheet = false

    /// Initialize a `ConfirmPaymentButton` with required parameters.
    public init(
      paymentSheetFlowController: PaymentSheet.FlowController,
      onCompletion: @escaping (PaymentResult) -> Void,
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
        isPresented: $showingPaymentSheet,
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
    let completion: (PaymentResult) -> Void

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

        // This is a bit of a hack: We traverse the view hierarchy looking for the most reasonable VC to present from.
        // A VC hosted within a SwiftUI cell, for example, doesn't have a parent, so we need to find the UIWindow.
        var presentingViewController = uiViewController.view.window?.rootViewController
        presentingViewController =
          presentingViewController?.presentedViewController ?? presentingViewController
          ?? uiViewController
        if let presentingViewController = presentingViewController {
          paymentSheet.present(from: presentingViewController) { (result) in
            self.parent.presented = false
            self.parent.completion(result)
          }
        }
      }

      private func forciblyDismissPaymentSheet() {
        if let bsvc = uiViewController.presentedViewController as? BottomSheetViewController {
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
    let paymentCompletion: ((PaymentResult) -> Void)?

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

        // This is a bit of a hack: We traverse the view hierarchy looking for the most reasonable VC to present from.
        // A VC hosted within a SwiftUI cell, for example, doesn't have a parent, so we need to find the UIWindow.
        var presentingViewController = uiViewController.view.window?.rootViewController
        presentingViewController =
          presentingViewController?.presentedViewController ?? presentingViewController
          ?? uiViewController
        if let presentingViewController = presentingViewController {
          switch parent.action {
          case .confirmPayment:
            flowController.confirmPayment(from: presentingViewController) { (result) in
              self.parent.presented = false
              self.parent.paymentCompletion!(result)
            }
          case .presentPaymentOptions:
            flowController.presentPaymentOptions(from: presentingViewController) {
              self.parent.presented = false
              self.parent.optionsCompletion?()
            }
          }
        }
      }

      private func forciblyDismissPaymentSheet() {
        if let bsvc = uiViewController.presentedViewController as? BottomSheetViewController {
          bsvc.didTapOrSwipeToDismiss()
        }
      }
    }
  }

  struct PaymentSheetPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let paymentSheet: PaymentSheet
    let completion: (PaymentResult) -> Void

    func body(content: Content) -> some View {
      content.background(
        PaymentSheetPresenter(
          presented: $isPresented,
          paymentSheet: paymentSheet,
          completion: completion
        )
      )
    }
  }

  enum FlowControllerAction {
    case presentPaymentOptions
    case confirmPayment
  }

  struct PaymentSheetFlowControllerPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    let paymentSheetFlowController: PaymentSheet.FlowController
    let action: FlowControllerAction
    let optionsCompletion: (() -> Void)?
    let paymentCompletion: ((PaymentResult) -> Void)?

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
