//
//  EmbeddedViewRepresentable.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/30/25.
//

import SwiftUI

struct EmbeddedViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: EmbeddedPaymentElementViewModel

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layoutMargins = .zero

        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else { return containerView }

        embeddedPaymentElement.presentingViewController = UIWindow.topMostViewController

        let paymentElementView = embeddedPaymentElement.view
        paymentElementView.layoutMargins = .zero
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(paymentElementView)

        let bottomConstraint = paymentElementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        // Lowering the priority prevents SwiftUI from hitting a required constraint so SwiftUI can gracefully resize the container
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomConstraint
        ])

        return containerView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the presenting view controller in case it has changed
        viewModel.embeddedPaymentElement?.presentingViewController = UIWindow.topMostViewController
    }
}

// MARK: UIWindow and UIViewController helpers

extension UIWindow {
    static var topMostViewController: UIViewController? {
        let window: UIWindow? = {
             // Check for connected scenes (for iOS 13 and later)
             if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                 if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                     return keyWindow
                 } else if let firstWindow = windowScene.windows.first {
                     return firstWindow
                 }
             }

             // Fallback for older iOS versions or if no scene is found
             if let appDelegateWindow = UIApplication.shared.delegate?.window ?? nil {
                 return appDelegateWindow
             }

             // As a last resort, try to find a keyWindow without a scene.
             if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                 return keyWindow
             }

             // No window found
             return nil
         }()

        return window?.rootViewController?.topMostViewController()
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let nav = self as? UINavigationController {
            // Use visibleViewController for nav stacks
            return nav.visibleViewController?.topMostViewController() ?? nav
        } else if let tab = self as? UITabBarController {
            // Use selectedViewController for tab controllers
            return tab.selectedViewController?.topMostViewController() ?? tab
        } else if let presented = presentedViewController {
            // Recurse for any modally presented controllers
            return presented.topMostViewController()
        }
        return self
    }
}
