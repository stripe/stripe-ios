//
//  PaymentElement.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 7/10/26.
//

@_spi(STP) import StripePayments
import SwiftUI
import UIKit

/// PaymentElement collects the customer's payment method, either in an embeddable view or presented in a sheet.
@MainActor
@_spi(STP)
public final class PaymentElement {
    /// A SwiftUI View that displays payment methods.
    public internal(set) var view: PaymentElementView

    /// A UIView that displays payment methods.
    public internal(set) var uiView: PaymentElementUIView

    init() {
        self.view = PaymentElementView()
        self.uiView = PaymentElementUIView()
    }

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// Returns when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil) async {
        // Placeholder.
    }

    /// Presents a sheet that displays payment methods.
    /// - Parameter from: The view controller that presents the sheet. If you're using SwiftUI, you may pass nil and it will use the topmost UIViewController from the key window.
    /// - Parameter completion: Called when the sheet is dismissed.
    public func present(from viewController: UIViewController? = nil, completion: (() -> Void)? = nil) {
        completion?()
    }
}

extension PaymentElement {
    /// Configuration for PaymentElement
    public struct Configuration {
        /// PaymentSheet offers users an option to save some payment methods for later use.
        /// Default value is `.automatic`.
        public var savePaymentMethodOptInBehavior: SavePaymentMethodOptInBehavior = .automatic

        /// Describes the appearance of PaymentElement.
        public var appearance: Appearance = .default

        /// The list of preferred networks that should be used to process payments made with a co-branded card.
        /// This value will only be used if your user hasn't selected a network themselves.
        public var preferredNetworks: [STPCardBrand]?

        /// Describes how billing details should be collected.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()

        /// Optional configuration to display a custom message when a saved payment method is removed.
        public var removeSavedPaymentMethodMessage: String?

        /// By default, PaymentElement will use a dynamic ordering that optimizes payment method display for the customer.
        public var paymentMethodOrder: [String]?

        /// By default, the card form will provide a button to open the card scanner.
        /// If true, the card form will instead initialize with the card scanner already open.
        public var opensCardScannerAutomatically: Bool = false

        /// When true, uses the Stripe autocomplete endpoints for billing address autocomplete instead of Apple MapKit.
        @_spi(STP) public var useAutocompleteEndpoints: Bool = false

        /// A map for specifying when legal agreements are displayed for each payment method type.
        public var termsDisplay: [STPPaymentMethodType: PaymentSheet.TermsDisplay] = [:]

        /// The layout of payment methods in the sheet. Defaults to `.automatic`.
        /// - Note: Only used if you call `PaymentElement.present(from:)`.
        public var paymentMethodLayout: PaymentMethodLayout = .automatic

        /// Controls whether the PaymentElement displays mandate text at the bottom for payment methods that require it. If set to `false`, your integration must display `PaymentOptionDisplayData.mandateText` to the customer near your “Buy” button to comply with regulations.
        /// - Note: This doesn't affect mandates displayed in the sheet and is ignored if you call `PaymentElement.present(from:)`.
        public var displaysMandateText: Bool = false

        /// Determines the behavior when a row is selected.
        /// - Note: Ignored if you call `PaymentElement.present(from:)`.
        public var rowSelectionBehavior: RowSelectionBehavior = .default

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
