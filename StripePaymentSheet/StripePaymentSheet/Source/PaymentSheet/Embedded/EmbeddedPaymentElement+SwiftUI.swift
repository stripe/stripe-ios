//
//  EmbeddedPaymentElement+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/9/25.
//

import SwiftUI
import Combine
@_spi(STP) import StripeCore

@_spi(EmbeddedPaymentElementPrivateBeta) public struct EmbeddedPaymentElementView: UIViewRepresentable {
    public class ViewModel: ObservableObject {
        @Published public var embeddedPaymentElement: EmbeddedPaymentElement?
        @Published public var height: CGFloat = 0
        
        public init() {}
    }
    
    @ObservedObject var viewModel: ViewModel
    @State private var isFirstLayout = true
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedSwiftUIProduct.self)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        if let element = viewModel.embeddedPaymentElement {
            element.delegate = context.coordinator
            element.presentingViewController = context.coordinator.topMostViewController()
            
            let paymentElementView = element.view
            containerView.addSubview(paymentElementView)
            paymentElementView.translatesAutoresizingMaskIntoConstraints = false
            let bottomConstraint = paymentElementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            bottomConstraint.priority = .defaultHigh
            
            NSLayoutConstraint.activate([
                paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
                paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bottomConstraint
            ])
        }
        
        return containerView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the presenting view controller in case it has changed
        viewModel.embeddedPaymentElement?.presentingViewController = context.coordinator.topMostViewController()
        
        DispatchQueue.main.async {
            let newHeight = uiView.systemLayoutSizeFitting(CGSize(width: uiView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
            if self.isFirstLayout {
                // No animation for the first layout
                self.viewModel.height = newHeight
                self.isFirstLayout = false
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.viewModel.height = newHeight
                }
            }
        }
    }

    public class Coordinator: NSObject, EmbeddedPaymentElementDelegate {
        var parent: EmbeddedPaymentElementView
        
        init(_ parent: EmbeddedPaymentElementView) {
            self.parent = parent
        }

        public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement _: EmbeddedPaymentElement) {
            self.parent.viewModel.objectWillChange.send()
        }

        public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement _: EmbeddedPaymentElement) {
            self.parent.viewModel.objectWillChange.send()
        }
        
        func topMostViewController() -> UIViewController {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let window = scene.windows.first(where: { $0.isKeyWindow }),
                let rootViewController = window.rootViewController
            else {
                return UIViewController()
            }
            return findTopViewController(from: rootViewController)
        }

        private func findTopViewController(from rootVC: UIViewController) -> UIViewController {
            if let presented = rootVC.presentedViewController {
                return findTopViewController(from: presented)
            }
            if let nav = rootVC as? UINavigationController,
               let visible = nav.visibleViewController {
                return findTopViewController(from: visible)
            }
            if let tab = rootVC as? UITabBarController,
               let selected = tab.selectedViewController {
                return findTopViewController(from: selected)
            }
            return rootVC
        }
    }
}

final class EmbeddedSwiftUIProduct: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "EmbeddedPaymentElement_SwiftUI"
    }
}
