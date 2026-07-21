//
//  LinkControllerDemoConfiguration.swift
//  PaymentSheet Example
//

@_spi(LinkControllerPreview) import StripePaymentSheet

struct LinkControllerDemoConfiguration {
    var email: String = "foo@bar.com"
    var phone: String = ""
    var supportedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    var paymentMethodTypesMode: PaymentMethodTypesMode = .automatic
    var intentMode: IntentMode = .sdkManaged

    var paymentMethodTypes: [String]? {
        switch paymentMethodTypesMode {
        case .automatic:
            return nil
        case .link:
            return ["link"]
        }
    }

    enum PaymentMethodTypesMode: String, CaseIterable {
        case automatic = "Automatic"
        case link = "Link"
    }

    enum IntentMode: String, CaseIterable {
        case sdkManaged = "SDK Managed"
        case serverSetupIntent = "Server SetupIntent"
    }
}
