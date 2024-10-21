//
//  EmbeddedPaymentElementContainerView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/16/24.
//
import UIKit

/// The view that's vended to the merchant, containing the embedded view.  We use this to be able to swap out the embedded view with an animation when `update` is called.
class EmbeddedPaymentElementContainerView: UIView {
    var updateSuperviewHeight: () -> Void = {}
    private var view: EmbeddedPaymentMethodsView
    private var bottomAnchorConstraint: NSLayoutConstraint!

    init(embeddedPaymentMethodsView: EmbeddedPaymentMethodsView) {
        self.view = embeddedPaymentMethodsView
        super.init(frame: .zero)
        addInitialView(view)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func addInitialView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        bottomAnchorConstraint = view.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            bottomAnchorConstraint,
        ])
    }

    func updateEmbeddedPaymentMethodsView(_ embeddedPaymentMethodsView: EmbeddedPaymentMethodsView) {
        guard frame.size != .zero else {
            // A zero frame means we haven't been laid out yet. Simply replace the old view to avoid laying out before the view is ready and breaking constraints.
            self.view.removeFromSuperview()
            self.view = embeddedPaymentMethodsView
            addInitialView(embeddedPaymentMethodsView)
            return
        }
        let oldView = view
        let oldViewHeight = frame.height
        // Add the new view w/ 0 alpha
        embeddedPaymentMethodsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(embeddedPaymentMethodsView)
        view = embeddedPaymentMethodsView
        embeddedPaymentMethodsView.alpha = 0
        NSLayoutConstraint.activate([
            embeddedPaymentMethodsView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            embeddedPaymentMethodsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            embeddedPaymentMethodsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            // Omit the bottom anchor so that the height is still fixed to the old view height
        ])
        // important that the view is already laid out before the animation block so that it doesn't animate from zero size.
        layoutIfNeeded()

        UIView.animate(withDuration: 0.2) {
            // Re-pin bottom anchor to the new view, thus updating our height
            self.bottomAnchorConstraint.isActive = false
            self.bottomAnchorConstraint = embeddedPaymentMethodsView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
            self.bottomAnchorConstraint.isActive = true
            self.layoutIfNeeded()
            // Fade old view out and new view in
            oldView.alpha = 0
            embeddedPaymentMethodsView.alpha = 1
            if oldViewHeight != self.systemLayoutSizeFitting(.zero).height {
                // Invoke EmbeddedPaymentElement delegate method so that height does not jump
                self.updateSuperviewHeight()
            }
        } completion: { _ in
            oldView.removeFromSuperview()
        }
    }
}
