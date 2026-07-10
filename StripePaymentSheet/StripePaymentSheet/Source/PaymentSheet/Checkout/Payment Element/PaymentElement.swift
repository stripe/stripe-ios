//
//  PaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
import SwiftUI
import UIKit

/// PaymentElement collects the customer's payment method, either in an embeddable view or presented in a sheet.
@MainActor
@_spi(STP)
public final class PaymentElement {
    // MARK: - Public Properties

    /// A SwiftUI View that displays payment methods.
    public internal(set) var view: PaymentElementView

    /// A UIView that displays payment methods.
    public internal(set) var uiView: PaymentElementUIView

    // MARK: - Public methods

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// Returns when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil) async {
        await withCheckedContinuation { continuation in
            present(from: viewController) {
                continuation.resume()
            }
        }
    }

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// - Parameter completion: Called when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil, completion: (() -> Void)? = nil) {
        guard let presentingViewController = viewController ?? UIWindow.visibleViewController else {
            let errorMessage = "PaymentElement.present(from:) could not find a presenting view controller."
            assertionFailure(errorMessage)
            let analytic = UnexpectedCheckoutElementsErrorAnalytic(
                errorCode: .paymentElementPresentingViewControllerUnavailable,
                errorMessage: errorMessage
            )
            STPAnalyticsClient.sharedClient.log(analytic: analytic)
            completion?()
            return
        }

        paymentSheetFlowController.presentPaymentOptions(from: presentingViewController) { _ in
            completion?()
        }
    }

    // MARK: - Internal Properties

    let paymentSheetFlowController: PaymentSheet.FlowController
    let embeddedPaymentElement: EmbeddedPaymentElement

    // MARK: - Internal methods

    init(checkout: Checkout) async throws {
        let paymentSheetConfiguration = checkout.configuration.paymentElement.makePaymentSheetConfiguration(
            apiClient: checkout.apiClient
        )
        self.paymentSheetFlowController = try await PaymentSheet.FlowController.create(
            checkout: checkout,
            configuration: paymentSheetConfiguration
        )
        let embeddedConfiguration = checkout.configuration.paymentElement.makeEmbeddedConfiguration(
            apiClient: checkout.apiClient
        )
        self.embeddedPaymentElement = try await EmbeddedPaymentElement.create(
            checkout: checkout,
            configuration: embeddedConfiguration
        )
        self.view = PaymentElementView()
        self.uiView = PaymentElementUIView()
    }
}

extension PaymentElement {
    /// Configuration for PaymentElement
    public struct Configuration {
        private var paymentSheetConfiguration = PaymentSheet.Configuration()
        private var embeddedConfiguration: EmbeddedPaymentElement.Configuration = {
            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.embeddedViewDisplaysMandateText = false
            return configuration
        }()

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

        /// When true, uses the Stripe autocomplete endpoints for billing address autocomplete instead of Apple MapKit.
        @_spi(STP) public var useAutocompleteEndpoints: Bool = false {
            didSet {
                paymentSheetConfiguration.useAutocompleteEndpoints = useAutocompleteEndpoints
                embeddedConfiguration.useAutocompleteEndpoints = useAutocompleteEndpoints
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

        /// Initializes a Configuration with default values.
        public init() {}

        /// Describes how you handle row selections in PaymentElement.
        public enum RowSelectionBehavior {
            /// When a payment option is selected, the customer taps a button to continue payment.
            case `default`

            /// When a payment option is selected, `didSelectPaymentOption` is triggered.
            /// You can implement this method to immediately perform an action e.g. go back to the checkout screen.
            case immediateAction(didSelectPaymentOption: () -> Void)
        }

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

// MARK: - UIKit

/// A view that displays payment methods.
@_spi(STP)
public final class PaymentElementUIView: UIView {
    /// A delegate for the view.
    public weak var delegate: PaymentElementViewDelegate?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@MainActor
@_spi(STP)
public protocol PaymentElementViewDelegate: AnyObject {
    /// Called inside an animation block when the PaymentElement view is updating its height.
    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView)

    /// Called immediately before the PaymentElement view presents.
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView)
}

public extension PaymentElementViewDelegate {
    func paymentElementViewWillPresent(paymentElementView: PaymentElementUIView) {
        // Default implementation does nothing.
    }
}

// MARK: - SwiftUI

/// A view that displays payment methods.
@_spi(STP)
public struct PaymentElementView: View {
    public init() {}

    public var body: some View {
        EmptyView()
    }
}
