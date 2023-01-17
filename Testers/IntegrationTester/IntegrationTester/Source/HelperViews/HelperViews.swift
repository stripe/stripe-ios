//
//  HelperViews.swift
//  IntegrationTester
//
//  Created by David Estes on 2/10/21.
//

import Stripe
import SwiftUI

struct PaymentHandlerStatusView: View {
  let actionStatus: STPPaymentHandlerActionStatus
  var lastPaymentError: NSError?

  var body: some View {
     HStack {
      switch actionStatus {
      case .succeeded:
        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        Text("Payment complete!")
      case .failed:
        Image(systemName: "xmark.octagon.fill").foregroundColor(.red)
        Text("Payment failed! \(lastPaymentError ?? NSError())")  // swiftlint:disable:this discouraged_direct_init
      case .canceled:
        Image(systemName: "xmark.octagon.fill").foregroundColor(.orange)
        Text("Payment canceled.")
      @unknown default:
        Text("Unknown status")
      }
    }
    .accessibility(identifier: "Payment status view")
  }
}

struct PaymentStatusView: View {
  let status: STPPaymentStatus
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
      @unknown default:
        Text("Unknown status")
      }
    }
    .accessibility(identifier: "Payment status view")
  }
}
