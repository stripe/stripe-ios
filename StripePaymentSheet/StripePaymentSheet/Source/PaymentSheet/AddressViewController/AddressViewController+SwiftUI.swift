//
//  AddressViewController+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import SwiftUI
#if canImport(UIKit)
import UIKit
private typealias AddressPlatformViewControllerRepresentable = UIViewControllerRepresentable
#elseif canImport(AppKit)
import AppKit
private typealias AddressPlatformViewControllerRepresentable = NSViewControllerRepresentable
#else
import Foundation
#endif

// MARK: - Internal Implementation

/// Internal UIViewControllerRepresentable wrapper for AddressViewController.
/// Use AddressElement instead of using this directly.
struct AddressViewControllerRepresentable: AddressPlatformViewControllerRepresentable {

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

    private func makeViewController(context: Context) -> UINavigationController {
        let addressViewController = AddressViewController(
            configuration: configuration,
            delegate: context.coordinator
        )
        context.coordinator.addressViewController = addressViewController

        let navigationController = UINavigationController(rootViewController: addressViewController)
        navigationController.preferredContentSize = UIView.layoutFittingExpandedSize
        return navigationController
    }

    private func updateViewController(_ viewController: UINavigationController, context: Context) {
        context.coordinator.address = $address
        context.coordinator.dismiss = dismiss

        var topController: UIViewController? = viewController
        while let parent = topController?.parent as? UIViewController {
            topController = parent
        }
        topController?.presentationController?.delegate = context.coordinator
    }

    #if canImport(UIKit)
    func makeUIViewController(context: Context) -> UINavigationController {
        makeViewController(context: context)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        updateViewController(uiViewController, context: context)
    }
    #elseif canImport(AppKit)
    func makeNSViewController(context: Context) -> UINavigationController {
        makeViewController(context: context)
    }

    func updateNSViewController(_ nsViewController: UINavigationController, context: Context) {
        updateViewController(nsViewController, context: context)
    }
    #endif

    func makeCoordinator() -> Coordinator {
        Coordinator(address: $address, dismiss: dismiss)
    }

    // MARK: - Coordinator

    /// Coordinator for AddressViewController delegate
    class Coordinator: NSObject, AddressViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        var address: Binding<AddressViewController.AddressDetails?>
        var dismiss: () -> Void
        weak var addressViewController: AddressViewController?

        init(address: Binding<AddressViewController.AddressDetails?>, dismiss: @escaping () -> Void) {
            self.address = address
            self.dismiss = dismiss
        }

        func addressViewControllerDidFinish(
            _ addressViewController: AddressViewController,
            with address: AddressViewController.AddressDetails?
        ) {
            dismiss()
            // Give some time for the sheet to dismiss before updating the address
            // SwiftUI doesn't have completion handlers for dismisses
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.address.wrappedValue = address
            }
        }

        // Called after the sheet has been dismissed by a swipe down
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            addressViewController?.didContinue()
        }
    }
}

// MARK: - Public API

/// A SwiftUI view that presents an address collection interface with full localization and autocomplete.
/// - Note: This view automatically handles keyboard presentation and dismissal.
/// - Seealso: https://stripe.com/docs/elements/address-element?platform=ios
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
        #if canImport(UIKit)
        // Ensure keyboard doesn't push up content and create layout issues
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #endif
    }
}

// MARK: - Analytics Integration

@_spi(STP) extension AddressElement: STPAnalyticsProtocol {
    public static let stp_analyticsIdentifier = "AddressElement"
}
