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
    private var contentView: UIView
    private var contentViewController: UIViewController?
    private var previousHeight: CGFloat?
    var notifiesDelegateOnInitialHeight = false
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

    func updateContentView(_ newContentView: UIView, viewController: UIViewController? = nil) {
        setContentViewController(viewController)
        guard contentView !== newContentView else { return }
        endEditing(true)
        previousHeight = nil
        guard frame.size != .zero else {
            bottomAnchorConstraint.isActive = false
            contentView.removeFromSuperview()
            contentView = newContentView
            setContentView(newContentView)
            return
        }
        let oldContentView = contentView

        // Add the new view
        newContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(newContentView)
        contentView = newContentView
        NSLayoutConstraint.activate([
            newContentView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            newContentView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            newContentView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        layoutIfNeeded()
        let heightWillChange = oldContentView.frame.height != newContentView.frame.height
        if heightWillChange {
            newContentView.alpha = 0
        }
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.2) {
            self.bottomAnchorConstraint.isActive = false
            self.bottomAnchorConstraint = newContentView.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
            self.bottomAnchorConstraint.isActive = true
            self.layoutIfNeeded()
            if heightWillChange {
                oldContentView.alpha = 0
                newContentView.alpha = 1
                self.needsUpdateSuperviewHeight()
            }
        } completion: { _ in
            if self.contentView !== oldContentView {
                oldContentView.removeFromSuperview()
            }
        }
    }

    /// Contains the active form controller, including forms nested beneath a payment method row.
    private func setContentViewController(_ viewController: UIViewController?) {
        guard contentViewController !== viewController else { return }
        contentViewController?.willMove(toParent: nil)
        contentViewController?.removeFromParent()
        contentViewController = viewController
        attachContentViewControllerIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            attachContentViewControllerIfNeeded()
        } else {
            contentViewController?.willMove(toParent: nil)
            contentViewController?.removeFromParent()
        }
    }

    private func attachContentViewControllerIfNeeded() {
        guard window != nil, let contentViewController, contentViewController.parent == nil else { return }
        var responder = next
        while let current = responder {
            if let parent = current as? UIViewController {
                parent.addChild(contentViewController)
                contentViewController.didMove(toParent: parent)
                return
            }
            responder = current.next
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The list reports its own height. Inline forms need the same notification contract.
        guard let contentViewController, contentViewController.view === contentView else { return }
        let height = systemLayoutSizeFitting(CGSize(width: frame.width, height: UIView.layoutFittingExpandedSize.height)).height
        let shouldNotify = previousHeight.map { $0 != height } ?? notifiesDelegateOnInitialHeight
        previousHeight = height
        if shouldNotify {
            needsUpdateSuperviewHeight()
        }
    }

}
