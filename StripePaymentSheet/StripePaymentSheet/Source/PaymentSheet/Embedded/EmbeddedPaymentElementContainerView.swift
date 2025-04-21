//
//  EmbeddedPaymentElementContainerView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/16/24.
//
import UIKit

/// The view that's vended to the merchant, containing the embedded view.  We use this to be able to swap out the embedded view with an animation when `update` is called.
class EmbeddedPaymentElementContainerView: UIView {
    
    /// Return the default size to let Auto Layout manage the height.
    /// Overriding intrinsicContentSize values and setting `invalidIntrinsicContentSize` forces SwiftUI to update layout immediately,
    /// resulting in abrupt, non-animated height changes.
    override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }
    
    var needsUpdateSuperviewHeight: () -> Void = {}
    private var contentView: EmbeddedPaymentMethodsView
    private var bottomAnchorConstraint: NSLayoutConstraint!

    init(embeddedPaymentMethodsView: EmbeddedPaymentMethodsView) {
        self.contentView = embeddedPaymentMethodsView
        super.init(frame: .zero)
        directionalLayoutMargins = .zero
        setContentView(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setContentView(_ view: UIView) {
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
            contentView.removeFromSuperview()
            contentView = embeddedPaymentMethodsView
            setContentView(embeddedPaymentMethodsView)
            return
        }
        let oldContentView = contentView

        // Add the new view
        embeddedPaymentMethodsView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(embeddedPaymentMethodsView)
        contentView = embeddedPaymentMethodsView
        NSLayoutConstraint.activate([
            embeddedPaymentMethodsView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            embeddedPaymentMethodsView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            embeddedPaymentMethodsView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            // Omit the bottom anchor so that the height is still fixed to the old view height
        ])

        // Lay the new view out before the animation block so that it doesn't animate from zero size.
        layoutIfNeeded()

        // Calculate heights of old and new content views to determine if height will change
        let oldContentViewHeight = oldContentView.frame.size.height
        let newContentViewHeight = embeddedPaymentMethodsView.frame.size.height
        let heightWillChange = oldContentViewHeight != newContentViewHeight

        // Fade the old view out and the new view in if the height will change
        if heightWillChange {
            embeddedPaymentMethodsView.alpha = 0
        }
        UIView.animate(withDuration: 0.2) {
            // Re-pin bottom anchor to the new view, thus updating our height
            self.bottomAnchorConstraint.isActive = false
            self.bottomAnchorConstraint = embeddedPaymentMethodsView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
            self.bottomAnchorConstraint.isActive = true
            self.layoutIfNeeded()
            if heightWillChange {
                oldContentView.alpha = 0
                embeddedPaymentMethodsView.alpha = 1
                // Invoke EmbeddedPaymentElement delegate method so that height of our superview does not jump
                self.needsUpdateSuperviewHeight()
            }
        } completion: { _ in
            oldContentView.removeFromSuperview()
        }
    }
}
