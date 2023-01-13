//
//  MainMenu.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import IntegrationTesterCommon
import SwiftUI

struct IntegrationView: View {
    let integrationMethod: IntegrationMethod

    var body: some View {
        switch integrationMethod {
        case .card:
            CardView()
        case .cardSetupIntents:
            CardSetupIntentsView()
        case .applePay:
            ApplePayView()
        case .fpx:
            FPXView()
        case .aubecsDebit:
            AUBECSDebitView()
        case .sepaDebit:
            SEPADebitView()
        case .sofort,
             .iDEAL,
             .alipay,
             .bacsDebit,
             .weChatPay:
            PaymentMethodView(integrationMethod: integrationMethod)
        case .oxxo,
             .giropay,
             .bancontact,
             .eps,
             .grabpay,
             .przelewy24:
            PaymentMethodWithContactInfoView(integrationMethod: integrationMethod)
        case .afterpay:
            PaymentMethodWithShippingInfoView(integrationMethod: integrationMethod)
        }
    }
}

struct MainMenu: View {
    var body: some View {
        NavigationView {
            List(IntegrationMethod.allCases, id: \.rawValue) { integrationMethod in
                NavigationLink(destination: IntegrationView(integrationMethod: integrationMethod)) {
                    Text(integrationMethod.rawValue)
                }
            }
            .navigationTitle("Integrations")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
    }
}
