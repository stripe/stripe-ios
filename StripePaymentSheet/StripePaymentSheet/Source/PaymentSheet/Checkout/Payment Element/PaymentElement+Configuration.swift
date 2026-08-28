//
//  PaymentElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension PaymentElement {
    /// Configuration for PaymentElement
    public struct Configuration {
        // MARK: - Public

        /// Initializes a Configuration with default values.
        public init() {}

        /// Configuration for Apple Pay.
        public var applePayConfiguration: ApplePayConfiguration?

        /// Configuration for Link.
        public var linkConfiguration: LinkConfiguration?

        /// PaymentSheet offers users an option to save some payment methods for later use.
        /// Default value is `.automatic`.
        public var savePaymentMethodOptInBehavior: SavePaymentMethodOptInBehavior = .automatic {
            didSet {
                paymentSheetConfiguration.savePaymentMethodOptInBehavior = savePaymentMethodOptInBehavior
                embeddedConfiguration.savePaymentMethodOptInBehavior = savePaymentMethodOptInBehavior
            }
        }

        /// Describes the appearance of PaymentElement.
        public var appearance: Appearance = .default {
            didSet {
                paymentSheetConfiguration.appearance = appearance
                embeddedConfiguration.appearance = appearance
            }
        }

        /// The list of preferred networks that should be used to process payments made with a co-branded card.
        /// This value will only be used if your user hasn't selected a network themselves.
        public var preferredNetworks: [STPCardBrand]? {
            didSet {
                paymentSheetConfiguration.preferredNetworks = preferredNetworks
                embeddedConfiguration.preferredNetworks = preferredNetworks
            }
        }

        /// Describes how billing details should be collected.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init() {
            didSet {
                paymentSheetConfiguration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
                embeddedConfiguration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
            }
        }

        /// Optional configuration to display a custom message when a saved payment method is removed.
        public var removeSavedPaymentMethodMessage: String? {
            didSet {
                paymentSheetConfiguration.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
                embeddedConfiguration.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
            }
        }

        /// By default, PaymentElement will use a dynamic ordering that optimizes payment method display for the customer.
        public var paymentMethodOrder: [String]? {
            didSet {
                paymentSheetConfiguration.paymentMethodOrder = paymentMethodOrder
                embeddedConfiguration.paymentMethodOrder = paymentMethodOrder
            }
        }

        /// By default, the card form will provide a button to open the card scanner.
        /// If true, the card form will instead initialize with the card scanner already open.
        public var opensCardScannerAutomatically: Bool = false {
            didSet {
                paymentSheetConfiguration.opensCardScannerAutomatically = opensCardScannerAutomatically
                embeddedConfiguration.opensCardScannerAutomatically = opensCardScannerAutomatically
            }
        }

        /// A map for specifying when legal agreements are displayed for each payment method type.
        public var termsDisplay: [STPPaymentMethodType: PaymentSheet.TermsDisplay] = [:] {
            didSet {
                paymentSheetConfiguration.termsDisplay = termsDisplay
                embeddedConfiguration.termsDisplay = termsDisplay
            }
        }

        /// The layout of payment methods in the sheet. Defaults to `.automatic`.
        /// - Note: Only used if you call `PaymentElement.present(from:)`.
        public var paymentMethodLayout: PaymentMethodLayout = .automatic {
            didSet {
                paymentSheetConfiguration.paymentMethodLayout = paymentMethodLayout
            }
        }

        /// Controls whether the PaymentElement displays mandate text at the bottom for payment methods that require it. If set to `false`, your integration must display `PaymentOptionDisplayData.mandateText` to the customer near your “Buy” button to comply with regulations.
        /// - Note: This doesn't affect mandates displayed in the sheet and is ignored if you call `PaymentElement.present(from:)`.
        public var displaysMandateText: Bool = false {
            didSet {
                embeddedConfiguration.embeddedViewDisplaysMandateText = displaysMandateText
            }
        }

        /// Determines the behavior when a row is selected.
        /// - Note: Ignored if you call `PaymentElement.present(from:)`.
        public var rowSelectionBehavior: RowSelectionBehavior = .default {
            didSet {
                embeddedConfiguration.rowSelectionBehavior = embeddedRowSelectionBehavior
            }
        }

        /// Describes how you handle row selections in PaymentElement.
        public enum RowSelectionBehavior {
            /// When a payment option is selected, the customer taps a button to continue payment.
            case `default`

            /// When a payment option is selected, `didSelectPaymentOption` is triggered.
            /// You can implement this method to immediately perform an action e.g. go back to the checkout screen.
            case immediateAction(didSelectPaymentOption: () -> Void)
        }

        // MARK: - Internal

        private var paymentSheetConfiguration = PaymentSheet.Configuration()
        private var embeddedConfiguration: EmbeddedPaymentElement.Configuration = {
            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.embeddedViewDisplaysMandateText = false
            return configuration
        }()

        func makeEmbeddedConfiguration(
            apiClient: STPAPIClient,
            returnURL: String,
            defaults: CheckoutController.Configuration.Defaults,
            merchantDisplayName: String,
            merchantCountryCode: String,
            userInterfaceStyle: CheckoutController.UserInterfaceStyle
        ) -> EmbeddedPaymentElement.Configuration {
            var configuration = embeddedConfiguration
            configuration.allowsDelayedPaymentMethods = true
            configuration.allowsPaymentMethodsRequiringShippingAddress = true
            configuration.apiClient = apiClient
            configuration.returnURL = returnURL
            configuration.apply(linkConfiguration: linkConfiguration)
            configuration.applePay = applePayConfiguration?.paymentSheetConfiguration(
                merchantCountryCode: merchantCountryCode
            )
            configuration.merchantDisplayName = merchantDisplayName
            configuration.style = userInterfaceStyle
            configuration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
            if let billingDetails = defaults.billingDetails {
                configuration.defaultBillingDetails.set(billingDetails)
            }
            configuration.defaultBillingDetails.email = defaults.email
            configuration.defaultBillingDetails.phone = defaults.phone
            return configuration
        }

        func makePaymentSheetConfiguration(
            apiClient: STPAPIClient,
            returnURL: String,
            defaults: CheckoutController.Configuration.Defaults,
            merchantDisplayName: String,
            merchantCountryCode: String,
            userInterfaceStyle: CheckoutController.UserInterfaceStyle
        ) -> PaymentSheet.Configuration {
            var configuration = paymentSheetConfiguration
            configuration.allowsDelayedPaymentMethods = true
            configuration.allowsPaymentMethodsRequiringShippingAddress = true
            configuration.apiClient = apiClient
            configuration.returnURL = returnURL
            configuration.apply(linkConfiguration: linkConfiguration)
            configuration.applePay = applePayConfiguration?.paymentSheetConfiguration(
                merchantCountryCode: merchantCountryCode
            )
            configuration.merchantDisplayName = merchantDisplayName
            configuration.style = userInterfaceStyle
            configuration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
            if let billingDetails = defaults.billingDetails {
                configuration.defaultBillingDetails.set(billingDetails)
            }
            configuration.defaultBillingDetails.email = defaults.email
            configuration.defaultBillingDetails.phone = defaults.phone
            return configuration
        }
    }
}

private extension PaymentElement.ApplePayConfiguration {
    func paymentSheetConfiguration(merchantCountryCode: String) -> PaymentSheet.ApplePayConfiguration {
        return PaymentSheet.ApplePayConfiguration(
            merchantId: merchantId,
            merchantCountryCode: merchantCountryCode,
            buttonType: buttonType ?? .plain
        )
    }
}

private extension PaymentSheet.Configuration {
    mutating func apply(linkConfiguration: PaymentElement.LinkConfiguration?) {
        switch linkConfiguration?.display {
        case .none, .automatic:
            link.display = .automatic
        case .never:
            link.display = .never
        case .walletButtonHidden:
            link.display = .walletButtonHidden
        }
    }
}

private extension EmbeddedPaymentElement.Configuration {
    mutating func apply(linkConfiguration: PaymentElement.LinkConfiguration?) {
        switch linkConfiguration?.display {
        case .none, .automatic:
            link.display = .automatic
        case .never:
            link.display = .never
        case .walletButtonHidden:
            link.display = .walletButtonHidden
        }
    }
}

// MARK: - Typealiases

extension PaymentElement {
    /// Describes the appearance of PaymentElement
    public typealias Appearance = PaymentSheet.Appearance
    public typealias SavePaymentMethodOptInBehavior = PaymentSheet.SavePaymentMethodOptInBehavior
    public typealias PaymentMethodLayout = PaymentSheet.PaymentMethodLayout

    /// Configuration for how billing details are collected during checkout.
    public struct BillingDetailsCollectionConfiguration: Equatable {
        /// Billing address collection options.
        public enum AddressCollectionMode: String, CaseIterable {
            /// Only the fields required by the Payment Method will be collected, this may be none.
            case automatic
            /// Collect the full billing address, regardless of the Payment Method requirements.
            case full
        }

        /// How to collect the billing address.
        /// Defaults to `automatic`.
        public var address: AddressCollectionMode = .automatic

        /// A set of two-letter country codes representing countries the customers can select.
        /// If the set is empty (the default), we display all countries.
        /// Country codes are automatically normalized to uppercase.
        /// - Note: Saved payment methods whose billing address country is not in this list are hidden.
        public var allowedCountries: Set<String> = [] {
            didSet {
                allowedCountries = Set(allowedCountries.map { $0.uppercased() })
            }
        }
    }
}

private extension PaymentElement.BillingDetailsCollectionConfiguration {
    func paymentSheetConfiguration() -> PaymentSheet.BillingDetailsCollectionConfiguration {
        var configuration = PaymentSheet.BillingDetailsCollectionConfiguration()
        configuration.address = address.paymentSheetAddressCollectionMode
        configuration.allowedCountries = allowedCountries
        return configuration
    }
}

private extension PaymentElement.BillingDetailsCollectionConfiguration.AddressCollectionMode {
    var paymentSheetAddressCollectionMode: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode {
        switch self {
        case .automatic:
            return .automatic
        case .full:
            return .full
        }
    }
}

private extension PaymentElement.Configuration {
    var embeddedRowSelectionBehavior: EmbeddedPaymentElement.Configuration.RowSelectionBehavior {
        switch rowSelectionBehavior {
        case .default:
            return .default
        case .immediateAction(let didSelectPaymentOption):
            return .immediateAction(didSelectPaymentOption: didSelectPaymentOption)
        }
    }
}

private extension PaymentSheet.BillingDetails {
    mutating func set(_ billingDetails: CheckoutController.Configuration.Defaults.BillingDetails) {
        name = billingDetails.name
        if let billingAddress = billingDetails.address {
            address.set(billingAddress)
        }
    }
}

private extension PaymentSheet.Address {
    mutating func set(_ address: CheckoutController.Address) {
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }
}
