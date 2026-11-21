//
//  PaneLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/12/22.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Reusable view that separates panes into two parts:
/// 1. A scroll view for content
/// 2. A footer that is "locked" and does not get affected by scroll view
///
/// Purposefully NOT a `UIView` subclass because it should only be used via
/// `addToView` helper function.
final class PaneLayoutView {

    private weak var scrollViewContentView: UIView?
    private let paneLayoutView: UIView
    let scrollView: UIScrollView

    /// Holds the footer in the stack and insets it to the safe area, because the stack spans the full width.
    private var footerContainerView: UIView?
    /// Pins `paneLayoutView` to the bottom of the presenting view's safe area.
    /// Its constant moves the footer above the keyboard.
    private var paneLayoutViewBottomConstraint: NSLayoutConstraint?
    private weak var presentingView: UIView?
    private let keepFooterAboveKeyboard: Bool

    /// Whether or not the sheet is currently presented as a form sheet (which only happens with a regular width).
    /// Unfortunately, the best way to know this is to check if the sheet's width is not equal to the window's width.
    private var isPresentedAsFormSheet: Bool {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return false }
        guard let presentingView else { return false }
        return window.frame.width != presentingView.frame.width
    }

    /// Only move the footer view when the sheet is not presented as a form sheet.
    /// Form sheet positions are already adjusted when the keyboard is shown.
    private var shouldMoveFooterViewAboveKeyboard: Bool {
        !isPresentedAsFormSheet
    }

    /// Creates a PaneLayoutView with the provided content view and footer view.
    /// In order to keep the footer view above the keyboard;
    /// - Set `keepFooterAboveKeyboard: true`.
    /// - Hold onto this instance of `PaneLayoutView` on the view controller presenting it.
    /// This is required to prevent the keyboard observer notifications be removed.
    init(contentView: UIView, footerView: UIView?, keepFooterAboveKeyboard: Bool = false) {
        self.scrollViewContentView = contentView
        self.keepFooterAboveKeyboard = keepFooterAboveKeyboard

        let scrollView = AutomaticShadowScrollView()
        self.scrollView = scrollView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // Content only scrolls vertically.
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                scrollView
            ]
        )
        if let footerView = footerView {
            let footerContainerView = HitTestView()
            footerView.translatesAutoresizingMaskIntoConstraints = false
            footerContainerView.addSubview(footerView)
            NSLayoutConstraint.activate([
                footerView.topAnchor.constraint(equalTo: footerContainerView.topAnchor),
                footerView.bottomAnchor.constraint(equalTo: footerContainerView.bottomAnchor),
                footerView.leadingAnchor.constraint(equalTo: footerContainerView.safeAreaLayoutGuide.leadingAnchor),
                footerView.trailingAnchor.constraint(equalTo: footerContainerView.safeAreaLayoutGuide.trailingAnchor),
            ])
            self.footerContainerView = footerContainerView
            verticalStackView.addArrangedSubview(footerContainerView)
        }
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical
        self.paneLayoutView = verticalStackView
    }

    /// Adds this `PaneLayoutView` to the provided view.
    func addTo(view: UIView) {
        // This function encapsulates an error-prone sequence where we
        // must add `paneLayoutView` (and all it's subviews) to the `view`
        // BEFORE we can add a constraint for `UIScrollView` content
        self.presentingView = view
        // Span the full width and extend under the top safe area, so the scroll view and its indicator
        // reach the screen edges (e.g. past the iPhone Duo's side column, and up to the sheet's top edge
        // when the navigation bar collapses), while the content and footer stay inside the safe area.
        paneLayoutView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paneLayoutView)
        // Keep the bottom constraint so the whole pane, including its footer, can move above the keyboard
        let paneLayoutViewBottomConstraint = paneLayoutView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        self.paneLayoutViewBottomConstraint = paneLayoutViewBottomConstraint
        NSLayoutConstraint.activate([
            paneLayoutView.topAnchor.constraint(equalTo: view.topAnchor),
            paneLayoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paneLayoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paneLayoutViewBottomConstraint,
        ])
        if let scrollViewContentView {
            NSLayoutConstraint.activate([
                scrollViewContentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                scrollViewContentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            ])
        }

        // Fit the scroll view height to be the size of the
        // scroll view contents
        //
        // For exampple, this is needed for `SheetViewController`
        // to automatically re-size the sheet to the size of contents
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        scrollViewHeightConstraint.isActive = true

        if keepFooterAboveKeyboard {
            setupKeyboardObservers()
        }
    }

    func createView() -> UIView {
        let containerView = UIView()
        addTo(view: containerView)
        return containerView
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard shouldMoveFooterViewAboveKeyboard else { return }
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        // Only move the footer view if the keyboard height is above 200px
        // This is to prevent false-positives of the keyboard being shown.
        guard keyboardSize.height > 200 else { return }
        animateAlongsideKeyboard(notification) { [weak self] in
            self?.updateFooterViewConstraints(keyboardHeight: keyboardSize.height)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        animateAlongsideKeyboard(notification) { [weak self] in
            self?.updateFooterViewConstraints(keyboardHeight: 0)
        }
    }

    private func updateFooterViewConstraints(keyboardHeight: CGFloat) {
        guard let presentingView, footerContainerView != nil, let paneLayoutViewBottomConstraint else { return }
        let adjustedKeyboardHeight: CGFloat
        if keyboardHeight > 0 {
            // Removes additional padding applied to footer view when showing above the keyboard.
            adjustedKeyboardHeight = keyboardHeight - (Constants.Layout.defaultVerticalPadding * 2)
        } else {
            adjustedKeyboardHeight = keyboardHeight
        }

        // Raise the bottom of the whole pane instead of constraining the footer directly.
        // The footer is the last arranged subview of `paneLayoutView`, which already pins it to the stack's bottom,
        // so a separate footer constraint would conflict with that and break a constraint.
        paneLayoutViewBottomConstraint.constant = -adjustedKeyboardHeight
        presentingView.layoutIfNeeded()
    }

    private func animateAlongsideKeyboard(
        _ notification: Notification,
        animations: @escaping () -> Void
    ) {
        let userInfo = notification.userInfo
        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber else {
            animations()
            return
        }

        let animationOption: UIView.AnimationOptions
        if let keyboardAnimationCurve = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: keyboardAnimationCurve)?.rawValue {
            animationOption = UIView.AnimationOptions(rawValue: ((UInt(curve << 16))))
        } else {
            animationOption = .curveEaseInOut
        }

        UIView.animate(
            withDuration: duration.doubleValue,
            delay: 0,
            options: [animationOption],
            animations: animations
        )
    }
}

// Automatically adds a shadow to the bottom
// if the content is scrollable
private class AutomaticShadowScrollView: UIScrollView {

    private var shadowView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // The content is inset horizontally through constraints, so only inset vertically here.
        // The scroll indicator is inset manually too, so it can sit past a side column (e.g. on iPhone Duo).
        contentInsetAdjustmentBehavior = .never
        automaticallyAdjustsScrollIndicatorInsets = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateHorizontalScrollIndicatorInsets()
        let topInset = safeAreaInsets.top
        guard contentInset.top != topInset else { return }
        let isScrolledToTop = contentOffset.y <= -contentInset.top
        contentInset.top = topInset
        verticalScrollIndicatorInsets.top = topInset
        if isScrolledToTop {
            contentOffset.y = -topInset
        }
    }

    /// Keeps the scroll indicator clear of the sensor housing and rounded corners, like UIKit does,
    /// except on the edge with the side column, where it sits at the screen edge.
    private func updateHorizontalScrollIndicatorInsets() {
        let verticalBarEdges = stp_verticalBarEdges ?? []
        let leftInset = verticalBarEdges.contains(.left) ? 0 : safeAreaInsets.left
        let rightInset = verticalBarEdges.contains(.right) ? 0 : safeAreaInsets.right
        if verticalScrollIndicatorInsets.left != leftInset || verticalScrollIndicatorInsets.right != rightInset {
            verticalScrollIndicatorInsets.left = leftInset
            verticalScrollIndicatorInsets.right = rightInset
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let canScroll = contentSize.height > bounds.height
        if canScroll && shadowView == nil {
            let shadowView = UIView()
            self.shadowView = shadowView
            shadowView.layer.shadowColor = FinancialConnectionsAppearance.Colors.textDefault.cgColor
            shadowView.layer.shadowOpacity = 0.77
            shadowView.layer.shadowOffset = CGSize(width: 0, height: -4)
            shadowView.layer.shadowRadius = 10
            // if the background color is clear, iOS will
            // not draw a shadow
            shadowView.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
            addSubview(shadowView)
        } else if !canScroll {
            shadowView?.removeFromSuperview()
            shadowView = nil
        }

        if let shadowView {
            // smaller shadow width "smoothens" the shadow
            // around the leading/trailing edges
            let inset = Constants.Layout.defaultHorizontalMargin / 2
            // keep the shadow inside the safe area, since the scroll view spans the full width
            let x = safeAreaInsets.left + inset
            // move the `shadowView` to keep being at the bottom of visible bounds
            shadowView.frame = CGRect(
                x: x,
                y: contentOffset.y + bounds.height,
                width: bounds.width - safeAreaInsets.left - safeAreaInsets.right - (2 * inset),
                height: 1
            )

            // slowly fade the `shadowView` as user scrolls to bottom
            //
            // the fade will only activate when we reach `startFadingDistanceToBottom`
            let distanceToBottom = contentSize.height - (contentOffset.y + bounds.size.height)
            let startFadingDistanceToBottom: CGFloat = 24
            let remainingFadeDistance = max(0, min(startFadingDistanceToBottom, distanceToBottom))
            shadowView.alpha = remainingFadeDistance / startFadingDistanceToBottom
        }
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // The side column's edge is a trait, and can change without the safe area changing.
        updateHorizontalScrollIndicatorInsets()
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        shadowView?.layer.shadowColor = FinancialConnectionsAppearance.Colors.textDefault.cgColor
    }
}
