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
        pip?.paymentMethodParams = self.integrationMethod.defaultPaymentMethodParams
        pip?.paymentMethodOptions = self.integrationMethod.defaultPaymentMethodOptions
        
        // WeChat Pay is the only supported Payment Method that doesn't allow a returnURL.
        if self.integrationMethod != .weChatPay {
            pip?.returnURL = BackendModel.returnURL
        }
        
        // TODO: For now, we set a beta flag only for WeChat Pay. We should remove this before public release + before WeChat Pay is out of beta.
        if self.integrationMethod == .weChatPay {
            STPAPIClient.shared.betas = [.weChatPayBetaV1]
        } else {
            STPAPIClient.shared.betas = []
        }
        
        self.paymentIntentParams = pip
    }
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, pi: STPPaymentIntent?, error: NSError?)
  {
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}
