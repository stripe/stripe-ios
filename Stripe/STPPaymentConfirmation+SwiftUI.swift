//
//  STPPaymentConfirmation+SwiftUI.swift
//  StripeiOS
//
//  Created by David Estes on 2/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
struct ConfirmPaymentPresenter: UIViewControllerRepresentable {
  @Binding var presented: Bool
  let paymentIntentParams: STPPaymentIntentParams
  let onCompletion: STPPaymentHandlerActionPaymentIntentCompletionBlock

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
      STPPaymentHandler.sharedHandler.confirmPayment(self.parent.paymentIntentParams, with: self) { (status, pi, error) in
        self.parent.presented = false
        self.parent.onCompletion(status, pi, error)
      }
    }

    private func forciblyDismissConfirmationSheet() {
      self.authenticationPresentingViewController().dismiss(animated: true)
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
        paymentIntentParams: paymentIntentParams,
        onCompletion: onCompletion
      )
    )
  }
}


@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
struct ConfirmPaymentPresentationModifier: ViewModifier {
  @Binding var isPresented: Bool
  let paymentIntentParams: STPPaymentIntentParams
  let onCompletion: STPPaymentHandlerActionPaymentIntentCompletionBlock

  func body(content: Content) -> some View {
    content.background(
      ConfirmPaymentPresenter(
        presented: $isPresented,
        paymentIntentParams: paymentIntentParams,
        onCompletion: onCompletion
      )
    )
  }
}
