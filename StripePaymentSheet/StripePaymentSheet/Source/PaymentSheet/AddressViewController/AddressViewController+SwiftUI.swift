//
//  AddressViewController+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import SwiftUI
import UIKit

// MARK: - Private Implementation

/// Private UIViewControllerRepresentable wrapper for AddressViewController.
/// Use AddressElement instead of using this directly.
@available(iOS 15.0, *)
private struct AddressViewControllerRepresentable: UIViewControllerRepresentable {

    // MARK: Properties

    /// Configuration for address collection
    private let configuration: AddressElement.Configuration
    /// Binding for collected address
    @Binding var address: AddressElement.AddressDetails?
    /// Dismissal closure
    private let dismiss: () -> Void

    // MARK: Initialization

    /// Initializes a AddressViewControllerRepresentable
    /// - Parameters:
    ///   - configuration: AddressElement configuration
    ///   - address: Binding to the collected address
    ///   - dismiss: A closure that when called dismisses the AddressElement
    init(
        configuration: AddressViewController.Configuration = AddressViewController.Configuration(),
        address: Binding<AddressViewController.AddressDetails?>,
        dismiss: @escaping () -> Void
    ) {
        self.configuration = configuration
        self._address = address
        self.dismiss = dismiss
    }

    // MARK: UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UINavigationController {
        let addressViewController = AddressViewController(
            configuration: configuration,
            delegate: context.coordinator
        )

        return UINavigationController(rootViewController: addressViewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.address = $address
        context.coordinator.dismiss = dismiss
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(address: $address, dismiss: dismiss)
    }

    // MARK: - Coordinator

    /// Coordinator for AddressViewController delegate
    class Coordinator: NSObject, AddressViewControllerDelegate {
        var address: Binding<AddressViewController.AddressDetails?>
        var dismiss: () -> Void

        init(address: Binding<AddressViewController.AddressDetails?>, dismiss: @escaping () -> Void) {
            self.address = address
            self.dismiss = dismiss
        }

        func addressViewControllerDidFinish(
            _ addressViewController: AddressViewController,
            with address: AddressViewController.AddressDetails?
        ) {
            self.address.wrappedValue = address
            dismiss()
        }
    }
}

// MARK: - Public API

/// A SwiftUI view that presents an address collection interface with full localization and autocomplete.
/// - Note: This view automatically handles keyboard presentation and dismissal.
/// - Seealso: https://stripe.com/docs/elements/address-element?platform=ios
@available(iOS 15.0, *)
public struct AddressElement: View {

    // MARK: - Types

    /// Configuration for an `AddressElement`.
    public typealias Configuration = AddressViewController.Configuration
    /// The customer data collected by `AddressElement`
    public typealias AddressDetails = AddressViewController.AddressDetails

    // MARK: Properties

    /// Configuration for the address collection e.g., to style the appearance.
    private let configuration: Configuration
    /// A valid address or nil.
    @Binding public var address: AddressDetails?
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss

    // MARK: Initialization

    /// Initializes an `AddressElement`.
    /// - Parameter address: This is updated when the customer completes entering their address or cancels the sheet.
    /// - Parameter configuration: The configuration for this `AddressElement` e.g., to style the appearance.
    public init(
        address: Binding<AddressDetails?>,
        configuration: Configuration
    ) {
        self._address = address
        self.configuration = configuration
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: Self.self)
    }

    // MARK: View Body

    public var body: some View {
        AddressViewControllerRepresentable(
            configuration: configuration,
            address: $address,
            dismiss: { dismiss() }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Analytics Integration

@available(iOS 15.0, *)
@_spi(STP) extension AddressElement: STPAnalyticsProtocol {
    public static let stp_analyticsIdentifier = "AddressElement"
}
