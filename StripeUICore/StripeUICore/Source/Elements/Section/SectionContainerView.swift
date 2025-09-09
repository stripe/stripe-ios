//
//  SectionContainerView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A rounded, lightly shadowed container view with a thin border.
 You can put views like TextFieldView inside it.
 It displays its views in a vertical stack with dividers between them.

 - Note: This class sets the borderWidth, color, cornerRadius, etc. of its subviews.
 
 For internal SDK use only
 */
@objc(STP_Internal_SectionContainerView)
class SectionContainerView: UIView {

    // MARK: - Views

    lazy var bottomPinningContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .top)
        view.directionalLayoutMargins = .zero
        view.addPinnedSubview(stackView)
        view.updateHeight()
        return view
    }()

    lazy var stackView: UIStackView = {
        let view = buildStackView(views: views, axis: .vertical, theme: theme)
        return view
    }()

    /// The list of views to display in a vertical stack
    private(set) var views: [UIView]
    private let theme: ElementsAppearance

    // MARK: - Initializers

    /**
     - Parameter views: A list of views to display in a row. To display multiple elements in a single row, put them inside a `MultiElementRowView`.
     */
    init(views: [UIView], theme: ElementsAppearance = .default) {
        self.views = views
        self.theme = theme
        super.init(frame: .zero)
        addAndPinSubview(bottomPinningContainerView)
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override var isUserInteractionEnabled: Bool {
        didSet {
            updateUI()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Improve shadow performance
        layer.shadowPath = CGPath(
            roundedRect: bounds,
            cornerWidth: layer.cornerRadius,
            cornerHeight: layer.cornerRadius,
            transform: nil
        )
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateUI()
    }
#endif

    func potentialFirstResponderIsInHierarchy(topView: UIView) -> Bool {
        if let rememberableTopView = topView as? TextFieldView.STPTextFieldThatRemembersWantingToBecomeFirstResponder,
           rememberableTopView.wantedToBecomeFirstResponder {
            return true
        }
        for subview in topView.subviews {
            return potentialFirstResponderIsInHierarchy(topView: subview)
        }
        return false
    }

    // MARK: - Internal methods
    func updateUI(newViews: [UIView]? = nil) {
        // Draw shadow (apply to self, not stackview, b/c stackview has clipsToBounds = true which will prevents the shadow from drawing)
        layer.applyShadow(shadow: theme.shadow)
        // Draw border
        stackView.layer.borderWidth = theme.borderWidth
        stackView.layer.borderColor = theme.colors.border.cgColor
        // Prevent subviews (specifically, TextFieldView's `transparentMaskView`) from extending outside the corners:
        stackView.clipsToBounds = true
        // Apply corner
        if LiquidGlassDetector.isEnabled {
            stackView.ios26_applyDefaultCornerConfiguration()
        } else {
            stackView.layer.cornerRadius = theme.cornerRadius
        }
        if isUserInteractionEnabled || UITraitCollection.current.isDarkMode {
            stackView.backgroundColor = theme.colors.componentBackground
        } else {
            stackView.backgroundColor = .tertiarySystemGroupedBackground
        }

        guard let newViews = newViews, views != newViews else {
            return
        }
        // Add new views in a new stack view
        let dummyFirstView: UIView? // A hack to preserve the first view during the transition
        let newStackViews: [UIView]
        if let first = newViews.first, first == views.first {
            // Hack: Give the new stack view a dummy view with the same height as the current stack view's first view
            let dummy = UIView(frame: first.frame)
            dummy.heightAnchor.constraint(equalToConstant: dummy.bounds.height).isActive = true
            newStackViews = [dummy] + newViews.dropFirst()
            dummyFirstView = dummy
        } else {
            dummyFirstView = nil
            newStackViews = newViews
        }

        let oldStackHeight = self.stackView.frame.size.height

        let newFirstResponder: UIView? = {
            for view in views {
                if potentialFirstResponderIsInHierarchy(topView: view) {
                    let oldFirstResponderIndex = views.firstIndex(of: view)
                    if let oldFirstResponderIndex = oldFirstResponderIndex, oldFirstResponderIndex < newViews.count {
                        return newViews[oldFirstResponderIndex]
                    }
                }
            }
            return nil
        }()

        let newStack = buildStackView(views: newStackViews, axis: .vertical, theme: theme)
        newStack.arrangedSubviews.forEach { $0.alpha = 0 }
        bottomPinningContainerView.addPinnedSubview(newStack)
        bottomPinningContainerView.layoutIfNeeded()
        let transition = {
            // Hack: Swap the dummy first view and real first view
            if let dummyFirstView = dummyFirstView,
               let firstView = self.views.first
            {
                self.stackView.insertArrangedSubview(dummyFirstView, at: 0)
                newStack.insertArrangedSubview(firstView, at: 0)
            }

            // Fade old out
            self.stackView.arrangedSubviews.forEach { $0.alpha = 0 }
            self.stackView.alpha = 0.0
            // Change height to accommodate new views
            self.bottomPinningContainerView.updateHeight()
            // Fade new in
            newStack.arrangedSubviews.forEach { $0.alpha = 1 }
            let oldStackView = self.stackView
            self.stackView = newStack
            self.views = newViews
            self.setNeedsLayout()
            self.layoutIfNeeded()
            oldStackView.removeFromSuperview()
        }
        let transitionCompletion: (Bool) -> Void = { _ in
            if let newFirstResponderTextField = newFirstResponder as? TextFieldView {
                _ = newFirstResponderTextField.textField.becomeFirstResponder()
            }
        }
        guard let viewController = window?.rootViewController?.presentedViewController else {
            transition()
            transitionCompletion(false)
            return
        }
        let shouldAnimate = Int(newStack.frame.size.height) != Int(oldStackHeight)
        viewController.animateHeightChange(duration: shouldAnimate ? 0.5 : 0.0, transition, completion: transitionCompletion)
    }
}

// MARK: - EventHandler

extension SectionContainerView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            isUserInteractionEnabled = false
        default:
            break
        }
    }
}

// MARK: - MultiElementRowView

extension SectionContainerView {
    class MultiElementRowView: UIView {
        init(views: [UIView], theme: ElementsAppearance) {
            super.init(frame: .zero)

            let stackView = buildStackView(views: views, axis: .horizontal, theme: theme)
            addAndPinSubview(stackView)

        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - StackViewWithSeparator

/// Builds the primary stack view that contains all others.
/// ⚠️ Don't modify stackView properties outside of this or it won't carry over when we call `buildStackView` again in `updateUI`
private func buildStackView(views: [UIView], axis: NSLayoutConstraint.Axis, theme: ElementsAppearance) -> UIStackView {
    // Add dividers between the views
    func createDivider() -> UIView {
        let divider = axis == .horizontal ? UIView.makeSpacerView(width: theme.separatorWidth) : UIView.makeSpacerView(height: theme.separatorWidth)
        divider.backgroundColor = theme.colors.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }
    let viewsWithDividersBetweenEach = views.enumerated().flatMap { index, view in
        index == views.count - 1 ? [view] : [view, createDivider()]
    }

    // Make the stackview
    let stackView = UIStackView(arrangedSubviews: viewsWithDividersBetweenEach)
    stackView.axis = axis
    stackView.distribution = .fill

    // Make all views equal width/height
    for i in 1..<views.count {
        if axis == .horizontal {
            views[i].widthAnchor.constraint(equalTo: views[0].widthAnchor).isActive = true
        } else {
            views[i].heightAnchor.constraint(equalTo: views[0].heightAnchor).isActive = true
        }
    }
    return stackView
}
