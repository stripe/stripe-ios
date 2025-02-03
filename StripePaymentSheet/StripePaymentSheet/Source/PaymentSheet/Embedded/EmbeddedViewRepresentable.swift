//
//  EmbeddedViewRepresentable.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/30/25.
//

import SwiftUI
@_spi(STP) import StripeCore

struct EmbeddedViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: EmbeddedPaymentElementViewModel

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layoutMargins = .zero

        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else {
            stpAssertionFailure("embeddedPaymentElement was nil in EmbeddedViewRepresentable.makeUIView(). Ensure you do not show the EmbeddedPaymentElementView before isLoaded is true on the EmbeddedPaymentElementViewModel.")
            return containerView
        }
        embeddedPaymentElement.presentingViewController = UIWindow.visibleViewController

        let paymentElementView = embeddedPaymentElement.view
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(paymentElementView)

        NSLayoutConstraint.activate([
            paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        return containerView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the presenting view controller in case it has changed
        viewModel.embeddedPaymentElement?.presentingViewController = UIWindow.visibleViewController
    }
}

// MARK: UIWindow and UIViewController helpers

extension UIWindow {    
    static var visibleViewController: UIViewController? {
        UIApplication.shared.stp_hackilyFumbleAroundUntilYouFindAKeyWindow()?.rootViewController?.topMostViewController
    }
}

extension UIViewController {
    var topMostViewController: UIViewController {
        if let nav = self as? UINavigationController {
            // Use visibleViewController for navigation stacks
            return nav.visibleViewController?.topMostViewController ?? nav
        } else if let tab = self as? UITabBarController {
            // Use selectedViewController for tab controllers
            return tab.selectedViewController?.topMostViewController ?? tab
        } else if let presented = presentedViewController {
            // Recurse for any presented controllers
            return presented.topMostViewController
        }
        
        return self
    }
}

