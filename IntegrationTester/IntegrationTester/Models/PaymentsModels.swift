//
//  PaymentsModels.swift
//  IntegrationTester
//
//  Created by David Estes on 2/18/21.
//

import Foundation
import Stripe

class MySIModel : ObservableObject {
  @Published var paymentStatus: STPPaymentHandlerActionStatus?
  @Published var intentParams: STPSetupIntentConfirmParams?
  @Published var lastPaymentError: NSError?
  var integrationMethod: IntegrationMethod = .cardSetupIntents
 
  func prepareSetupIntent() {
    BackendModel.shared.fetchSetupIntent { sip in
        sip?.returnURL = BackendModel.returnURL
        self.intentParams = sip
    }
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, si: STPSetupIntent?, error: NSError?) {
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}

class MyPIModel : ObservableObject {
  @Published var paymentStatus: STPPaymentHandlerActionStatus?
  @Published var paymentIntentParams: STPPaymentIntentParams?
  @Published var lastPaymentError: NSError?
    var integrationMethod: IntegrationMethod = .card

  func preparePaymentIntent() {
    // Enable this flag to test app-to-app redirects.
    STPPaymentHandler.shared().simulateAppToAppRedirect = true

    BackendModel.shared.fetchPaymentIntent(integrationMethod: integrationMethod) { pip in
        pip?.returnURL = BackendModel.returnURL
        self.paymentIntentParams = pip
    }
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, pi: STPPaymentIntent?, error: NSError?)
  {
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}
