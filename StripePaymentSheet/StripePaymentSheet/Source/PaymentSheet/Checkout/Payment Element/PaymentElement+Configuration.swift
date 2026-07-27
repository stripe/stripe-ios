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
            defaults: Checkout.Configuration.Defaults
        ) -> EmbeddedPaymentElement.Configuration {
            var configuration = embeddedConfiguration
            configuration.apiClient = apiClient
            configuration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
            if let billingDetails = defaults.billingDetails {
                configuration.defaultBillingDetails.set(billingDetails)
            }
            return configuration
        }

        func makePaymentSheetConfiguration(
            apiClient: STPAPIClient,
            defaults: Checkout.Configuration.Defaults
        ) -> PaymentSheet.Configuration {
            var configuration = paymentSheetConfiguration
            configuration.apiClient = apiClient
            configuration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration.paymentSheetConfiguration()
            if let billingDetails = defaults.billingDetails {
                configuration.defaultBillingDetails.set(billingDetails)
            }
            return configuration
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
        /// Billing details fields collection options.
        public enum CollectionMode: String, CaseIterable {
            /// The field will be collected depending on the Payment Method's requirements.
            case automatic
            /// The field will always be collected, even if it isn't required for the Payment Method.
            case always
        }

        /// Billing address collection options.
        public enum AddressCollectionMode: String, CaseIterable {
            /// Only the fields required by the Payment Method will be collected, this may be none.
            case automatic
            /// Collect the full billing address, regardless of the Payment Method requirements.
            case full
        }

        /// How to collect the name field.
        /// Defaults to `automatic`.
        public var name: CollectionMode = .automatic

        /// How to collect the phone field.
        /// Defaults to `automatic`.
        public var phone: CollectionMode = .automatic

        /// How to collect the email field.
        /// Defaults to `automatic`.
        /// - Note: Intentionally non-public, unclear what the merchant use case for this is given they need to provide an email up-front.
        let email: CollectionMode = .automatic

        /// How to collect the billing address.
        /// Defaults to `automatic`.
        public var address: AddressCollectionMode = .automatic

        /// Whether the values included in `Configuration.defaultBillingDetails` should be attached to the payment
        /// method, this includes fields that aren't displayed in the form.
        ///
        /// If `false` (the default), those values will only be used to prefill the corresponding fields in the form.
        public var attachDefaultsToPaymentMethod = false

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
        configuration.name = .init(rawValue: name.rawValue)!
        configuration.phone = .init(rawValue: phone.rawValue)!
        configuration.email = .init(rawValue: email.rawValue)!
        configuration.address = address.paymentSheetAddressCollectionMode
        configuration.attachDefaultsToPaymentMethod = attachDefaultsToPaymentMethod
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
    mutating func set(_ billingDetails: Checkout.Configuration.Defaults.BillingDetails) {
        name = billingDetails.name
        if let billingAddress = billingDetails.address {
            address.set(billingAddress)
        }
    }
}

private extension PaymentSheet.Address {
    mutating func set(_ address: Checkout.Address) {
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }
}
