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

    lazy var stackView: StackViewWithSeparator = {
        let view = buildStackView(views: views, theme: theme)
        return view
    }()

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
        // Set up each subviews border corners
        // Do this in layoutSubviews to update when views appear or disappear
        let visibleRows = stackView.arrangedSubviews.filter { !$0.isHidden }
        // 1. Reset all border corners to be square
        for row in visibleRows {
            // Pull out any Element views nested inside a MultiElementRowView
            for view in (row as? MultiElementRowView)?.views ?? [row] {
                view.layer.cornerRadius = theme.cornerRadius
                view.layer.maskedCorners = []
                view.layer.shadowOpacity = 0.0
                view.layer.borderWidth = 0
                view.layer.masksToBounds = true
            }
        }
        // 2. Round the top-most view's top corners
        if let multiElementRowView = visibleRows.first as? MultiElementRowView {
            multiElementRowView.views.first?.layer.maskedCorners.insert([.layerMinXMinYCorner])
            multiElementRowView.views.last?.layer.maskedCorners.insert([.layerMaxXMinYCorner])
        } else {
            visibleRows.first?.layer.maskedCorners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        }
        // 3. Round the bottom-most view's bottom corners
        if let multiElementRowView = visibleRows.last as? MultiElementRowView {
            multiElementRowView.views.first?.layer.maskedCorners.insert([.layerMinXMaxYCorner])
            multiElementRowView.views.last?.layer.maskedCorners.insert([.layerMaxXMaxYCorner])
        } else {
            visibleRows.last?.layer.maskedCorners.insert([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        }

        // Improve shadow performance
        layer.shadowPath = CGPath(
            roundedRect: bounds,
            cornerWidth: layer.cornerRadius,
            cornerHeight: layer.cornerRadius,
            transform: nil
        )
    }

#if !canImport(CompositorServices)
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
        layer.applyShadow(shadow: theme.shadow)
        layer.cornerRadius = theme.cornerRadius

        if isUserInteractionEnabled || UITraitCollection.current.isDarkMode {
            backgroundColor = theme.colors.componentBackground
        } else {
            backgroundColor = .tertiarySystemGroupedBackground
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

        let newStack = buildStackView(views: newStackViews, theme: theme)
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
        let views: [UIView]

        init(views: [UIView], theme: ElementsAppearance = .default) {
            self.views = views
            super.init(frame: .zero)
            let stackView = buildStackView(views: views, theme: theme)
            stackView.axis = .horizontal
            stackView.drawBorder = false
            stackView.distribution = .fillEqually
            addAndPinSubview(stackView)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - StackViewWithSeparator

private func buildStackView(views: [UIView], theme: ElementsAppearance = .default) -> StackViewWithSeparator {
    let stackView = StackViewWithSeparator(arrangedSubviews: views)
    stackView.axis = .vertical
    stackView.spacing = theme.borderWidth
    stackView.separatorColor = theme.colors.divider
    stackView.borderColor = theme.colors.border
    stackView.borderCornerRadius = theme.cornerRadius
    stackView.customBackgroundColor = theme.colors.componentBackground
    stackView.drawBorder = true
    stackView.hideShadow = true // Shadow is handled by `SectionContainerView`
    return stackView
}
