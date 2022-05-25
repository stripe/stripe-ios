//
//  ContentView.swift
//  Shared
//
//  Created by David Estes on 1/7/22.
//

import SwiftUI
import StripeApplePay

struct ContentView: View {
    @StateObject var model = MyApplePayBackendModel()
    @State var ready = false
    
    var body: some View {
        if ready {
            VStack {
                PaymentButton() {
                  model.pay()
                }
                .padding()
              if let paymentStatus = model.paymentStatus {
                PaymentStatusView(status: paymentStatus, lastPaymentError: model.lastPaymentError)
              }
            }
        } else {
            ProgressView().onAppear {
                BackendModel.shared.loadPublishableKey { pubKey in
                    STPAPIClient.shared.publishableKey = pubKey
                    ready = true
                }
            }
        }
    }
}

struct PaymentStatusView: View {
  let status: STPApplePayContext.PaymentStatus
  var lastPaymentError: Error?

  var body: some View {
     HStack {
      switch status {
      case .success:
        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        Text("Payment complete!")
      case .error:
        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
        Text("Payment failed! \(lastPaymentError.debugDescription)")
      case .userCancellation:
        Image(systemName: "xmark.octagon.fill").foregroundColor(.orange)
        Text("Payment canceled.")
      }
    }
    .accessibility(identifier: "Payment status view")
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
