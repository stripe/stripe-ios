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

    init(viewModel: EmbeddedPaymentElementViewModel) {
        self.viewModel = viewModel
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedSwiftUIProduct.self)
    }
    
    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layoutMargins = .zero

        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else { return containerView }
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
    static var current: UIWindow? {
        #if os(visionOS)
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .flatMap { $0 }
            .sorted { first, _ in first.isKeyWindow }
            .first
        #else
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: \.isKeyWindow)
        #endif
    }
    
    static var visibleViewController: UIViewController? {
        current?.rootViewController?.topMostViewController
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

final class EmbeddedSwiftUIProduct: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "EmbeddedPaymentElement_SwiftUI"
    }
}

