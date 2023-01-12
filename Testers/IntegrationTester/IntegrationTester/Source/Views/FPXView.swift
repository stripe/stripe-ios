//
//  CardView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import Stripe
import SwiftUI

struct FPXView: View {
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false

  var body: some View {
      VStack {
        if let paymentStatus = model.paymentStatus {
          PaymentHandlerStatusView(actionStatus: paymentStatus, lastPaymentError: model.lastPaymentError)
        } else {
          if let paymentIntent = model.paymentIntentParams {
            STPBankSelectionViewController.Representable(onCompletion: { paymentMethodParams in
              paymentIntent.paymentMethodParams = paymentMethodParams
              isConfirmingPayment = true
            }).paymentConfirmationSheet(isConfirmingPayment: $isConfirmingPayment,
                                       paymentIntentParams: paymentIntent,
                                       onCompletion: model.onCompletion)
            .disabled(isConfirmingPayment)
          } else {
            ProgressView()
          }
        }
      }.onAppear {
        model.integrationMethod = .fpx
        model.preparePaymentIntent()
      }
    }
}

struct FPXView_Preview: PreviewProvider {
  static var previews: some View {
    FPXView()
  }
}

extension STPBankSelectionViewController {
  struct Representable: UIViewControllerRepresentable {
    let onCompletion: (STPPaymentMethodParams?) -> Void

    public init(onCompletion: @escaping (STPPaymentMethodParams?) -> Void) {
      self.onCompletion = onCompletion
    }

    func makeCoordinator() -> Coordinator {
      return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
      return context.coordinator.vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
      context.coordinator.parent = self
    }

    class Coordinator: NSObject, STPBankSelectionViewControllerDelegate {
      func bankSelectionViewController(_ bankViewController: STPBankSelectionViewController, didCreatePaymentMethodParams paymentMethodParams: STPPaymentMethodParams) {
        self.parent.onCompletion(paymentMethodParams)
      }

      var parent: Representable
      init(parent: Representable) {
        self.parent = parent
        vc = STPBankSelectionViewController(bankMethod: .FPX)
        super.init()
        vc.delegate = self
      }

      let vc: STPBankSelectionViewController
    }
  }
}
