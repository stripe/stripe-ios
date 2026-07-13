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
                paymentSheetConfiguration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
                embeddedConfiguration.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
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

        func makeEmbeddedConfiguration(apiClient: STPAPIClient) -> EmbeddedPaymentElement.Configuration {
            var configuration = embeddedConfiguration
            configuration.apiClient = apiClient
            return configuration
        }

        func makePaymentSheetConfiguration(apiClient: STPAPIClient) -> PaymentSheet.Configuration {
            var configuration = paymentSheetConfiguration
            configuration.apiClient = apiClient
            return configuration
        }
    }
}

// MARK: - Typealiases

extension PaymentElement {
    /// Describes the appearance of PaymentElement
    public typealias Appearance = PaymentSheet.Appearance
    public typealias SavePaymentMethodOptInBehavior = PaymentSheet.SavePaymentMethodOptInBehavior
    public typealias BillingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration
    public typealias PaymentMethodLayout = PaymentSheet.PaymentMethodLayout
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
