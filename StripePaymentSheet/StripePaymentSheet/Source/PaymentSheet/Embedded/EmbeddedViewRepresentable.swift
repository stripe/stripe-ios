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
        let containerView = EmbeddedViewContainerView()
        containerView.backgroundColor = .clear
        containerView.layoutMargins = .zero
        containerView.didMoveToWindowHandler = {
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
            }
        }

        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else {
            stpAssertionFailure("embeddedPaymentElement was nil in EmbeddedViewRepresentable.makeUIView(). Ensure you do not show the EmbeddedPaymentElementView before isLoaded is true on the EmbeddedPaymentElementViewModel.")
            return containerView
        }

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
        guard let visibleVC = visibleViewController(for: uiView) else { return }

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

    private func visibleViewController(for uiView: UIView) -> UIViewController? {
        return uiView.window?.rootViewController?.findTopMostPresentedViewController()
    }
}

private final class EmbeddedViewContainerView: UIView {
    var didMoveToWindowHandler: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMoveToWindowHandler?()
    }
}

// MARK: UIWindow and UIViewController helpers

extension UIWindow {
    static var visibleViewController: UIViewController? {
        UIApplication.shared.stp_hackilyFumbleAroundUntilYouFindAKeyWindow()?.rootViewController?.findTopMostPresentedViewController()
    }
}
