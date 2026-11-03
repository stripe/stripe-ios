// From the iOS integration guide's setup import and controller configuration example.
@_spi(CheckoutSessionPreview) import StripePaymentSheet

@MainActor
func guideConfiguration(clientSecret: String) -> CheckoutController.Configuration {
    CheckoutController.Configuration(
        clientSecret: clientSecret,
        returnURL: "my-app://stripe-redirect"
    )
}
