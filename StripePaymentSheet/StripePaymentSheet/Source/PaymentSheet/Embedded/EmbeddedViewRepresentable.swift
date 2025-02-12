//
//  EmbeddedViewRepresentable.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/30/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI

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
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        return containerView
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        guard let visibleVC = UIWindow.visibleViewController else { return }

        // If visibleVC in the process of dismissing, skip for now and retry shortly.
        // updateUIView can be trigged by a view controller (such as a form) being dismissed
        guard !visibleVC.isBeingDismissed else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Re-trigger SwiftUI’s update cycle
                viewModel.objectWillChange.send()
            }
            return
        }

        if !(visibleVC is StripePaymentSheet.BottomSheetViewController) {
            viewModel.embeddedPaymentElement?.presentingViewController = visibleVC
        }
    }
}

// MARK: UIWindow and UIViewController helpers

extension UIWindow {
    static var visibleViewController: UIViewController? {
        UIApplication.shared.stp_hackilyFumbleAroundUntilYouFindAKeyWindow()?.rootViewController?.findTopMostPresentedViewController()
    }
}
