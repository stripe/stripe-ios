//
//  LinkControllerDemoConfiguration.swift
//  PaymentSheet Example
//

@_spi(LinkControllerPreview) import StripePaymentSheet

struct LinkControllerDemoConfiguration {
    var email: String = ""
    var phone: String = ""
    var supportedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    var intentMode: IntentMode = .sdkManaged

    enum IntentMode: String, CaseIterable {
        case sdkManaged = "SDK Managed"
        case serverSetupIntent = "Server SetupIntent"
    }
}
