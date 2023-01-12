//
//  CardView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import Stripe
import SwiftUI

struct AUBECSDebitView: View {
  @StateObject var model = MyPIModel()
  @State var isConfirmingPayment = false
  @State var paymentMethodParams: STPPaymentMethodParams?

  var body: some View {
      VStack {
        STPAUBECSDebitFormView.Representable(paymentMethodParams: $paymentMethodParams)
          .frame(maxHeight: 400)
        if let paymentIntent = model.paymentIntentParams {
          Button("Buy") {
            paymentIntent.paymentMethodParams = paymentMethodParams
            isConfirmingPayment = true
          }.paymentConfirmationSheet(isConfirmingPayment: $isConfirmingPayment,
                                     paymentIntentParams: paymentIntent,
                                     onCompletion: model.onCompletion)
          .disabled(isConfirmingPayment || paymentMethodParams == nil)
        } else {
          ProgressView()
        }
        if let paymentStatus = model.paymentStatus {
          PaymentHandlerStatusView(actionStatus: paymentStatus, lastPaymentError: model.lastPaymentError)
        }
      }.onAppear {
        model.integrationMethod = .aubecsDebit
        model.preparePaymentIntent()
      }
    }
}

struct AUBECSDebitView_Preview: PreviewProvider {
  static var previews: some View {
    AUBECSDebitView()
  }
}

extension STPAUBECSDebitFormView {
  public struct Representable: UIViewRepresentable {
    @Binding var paymentMethodParams: STPPaymentMethodParams?

    public init(paymentMethodParams: Binding<STPPaymentMethodParams?>) {
      _paymentMethodParams = paymentMethodParams
    }

    public func makeCoordinator() -> Coordinator {
      return Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> STPAUBECSDebitFormView {
      let formView = STPAUBECSDebitFormView(companyName: "Test")
      formView.becsDebitFormDelegate = context.coordinator
      formView.setContentHuggingPriority(.required, for: .vertical)

      return formView
    }

    public func updateUIView(_ formView: STPAUBECSDebitFormView, context: Context) {
    }

    public class Coordinator: NSObject, STPAUBECSDebitFormViewDelegate {
      var parent: Representable
      init(parent: Representable) {
        self.parent = parent
      }

      public func auBECSDebitForm(_ form: STPAUBECSDebitFormView, didChangeToStateComplete complete: Bool) {
        parent.paymentMethodParams = form.paymentMethodParams
      }
    }
  }
}
