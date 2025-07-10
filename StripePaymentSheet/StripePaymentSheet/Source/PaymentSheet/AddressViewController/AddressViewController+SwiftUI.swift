//
//  AddressViewController+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import SwiftUI
import UIKit
@_spi(STP) import StripeCore

/// Private implementation of UIViewControllerRepresentable for AddressViewController.
/// Use AddressElement instead of using this directly.
@available(iOS 15.0, *)
private struct AddressViewControllerRepresentable: UIViewControllerRepresentable {
    /// Configuration for the address collection
    private let configuration: AddressViewController.Configuration
    /// Binding for the collected address
    @Binding var address: AddressViewController.AddressDetails?
    /// Environment dismiss action for automatic dismissal
    private let dismiss: () -> Void
    
    /// Initializes the address collection view
    /// - Parameters:
    ///   - configuration: Configuration for appearance and behavior
    ///   - address: Binding to the collected address
    ///   - dismiss: Closure to dismiss the view
    init(
        configuration: AddressViewController.Configuration = AddressViewController.Configuration(),
        address: Binding<AddressViewController.AddressDetails?>,
        dismiss: @escaping () -> Void
    ) {
        self.configuration = configuration
        self._address = address
        self.dismiss = dismiss
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let addressViewController = AddressViewController(
            configuration: configuration,
            delegate: context.coordinator
        )
        
        return UINavigationController(rootViewController: addressViewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Update the coordinator's binding and dismiss closure if needed
        context.coordinator.address = $address
        context.coordinator.dismiss = dismiss
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(address: $address, dismiss: dismiss)
    }
    
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
            // Update the binding with the collected address
            self.address.wrappedValue = address
            dismiss()
        }
    }
}

/// A SwiftUI view that presents an AddressViewController for collecting address information.
/// This handles keyboard presentation properly and provides a clean SwiftUI interface.
@available(iOS 15.0, *)
public struct AddressElement: View {
    /// Configuration for the address collection
    public let configuration: AddressViewController.Configuration
    /// Binding for the collected address
    @Binding public var address: AddressViewController.AddressDetails?
    /// Environment dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Initializes the address element
    /// - Parameters:
    ///   - address: Binding to the collected address
    ///   - configuration: Configuration for appearance and behavior
    public init(
        address: Binding<AddressViewController.AddressDetails?>,
        configuration: AddressViewController.Configuration = AddressViewController.Configuration()
    ) {
        self._address = address
        self.configuration = configuration
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: Self.self)
    }
    
    public var body: some View {
        AddressViewControllerRepresentable(
            configuration: configuration,
            address: $address,
            dismiss: { dismiss() }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: STPAnalyticsProtocol

@available(iOS 15.0, *)
@_spi(STP) extension AddressElement: STPAnalyticsProtocol {
    public static let stp_analyticsIdentifier = "AddressElement"
} 
