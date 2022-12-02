//
//  CardView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import SwiftUI
import Stripe

struct ApplePayView: View {
  @StateObject var model = MyApplePayBackendModel()

  var body: some View {
      VStack {
          PaymentButton() {
            model.pay()
          }
          .padding()
        if let paymentStatus = model.paymentStatus {
          PaymentStatusView(status: paymentStatus, lastPaymentError: model.lastPaymentError)
        }
      }
  }
}

struct ApplePayView_Preview : PreviewProvider {
  static var previews: some View {
    ApplePayView()
  }
}
