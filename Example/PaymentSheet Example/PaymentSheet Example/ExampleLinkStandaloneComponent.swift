//
//  ExampleLinkStandaloneComponent.swift
//  PaymentSheet Example
//
//  Created by Till Hellmund on 6/19/25.
//

import StripePaymentSheet
import SwiftUI

struct ExampleLinkStandaloneComponent: View {
    private var linkController: LinkController {
        LinkController.create()
    }

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Button("Pay with Link", action: presentLink)
            Spacer()
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

        linkController.present(from: viewController, with: "email@email.com") {
            print(linkController.paymentOption?.label ?? "no payment method")
        }
    }
}

private func findViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    var topController = keyWindow?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
        topController = presentedViewController
    }
    return topController
}

struct ExampleLinkStandaloneComponent_Previews: PreviewProvider {
    static var previews: some View {
        ExampleLinkStandaloneComponent()
    }
}
