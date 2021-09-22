//
//  ContainerView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 Returns a rounded, lightly shadowed view with a thin border.
 You can put e.g., text fields inside it.
 */
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
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.spacing = -ElementsUI.fieldBorderWidth
        stackView.axis = .vertical
        return stackView
    }()
    
    private(set) var views: [UIView]

    // MARK: - Initializers

    convenience init(view: UIView) {
        self.init(views: [view])
    }
    
    init(views: [UIView]) {
        self.views = views
        super.init(frame: .zero)
        backgroundColor = ElementsUI.backgroundColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 4
        layer.cornerRadius = ElementsUI.defaultCornerRadius
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
        let subviews = stackView.arrangedSubviews.filter { !$0.isHidden }
        // 1. Reset all border corners to be square
        for view in subviews {
            view.layer.cornerRadius = ElementsUI.defaultCornerRadius
            view.layer.borderWidth = ElementsUI.fieldBorderWidth
            view.layer.maskedCorners = []
            view.layer.shadowOpacity = 0.0
        }
        // 2. Round the top-most view's top corners
        subviews.first?.layer.maskedCorners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
        // 3. Round the bottom-most view's bottom corners
        subviews.last?.layer.maskedCorners.insert([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])

        // Improve shadow performance
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateUI()
    }

    // MARK: - Internal methods

    func updateUI(newViews: [UIView]? = nil) {
        if isUserInteractionEnabled || isDarkMode() {
            backgroundColor = ElementsUI.backgroundColor
        } else {
            backgroundColor = CompatibleColor.tertiarySystemGroupedBackground
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
        let newStack = UIStackView(arrangedSubviews: newStackViews)
        newStack.spacing = -ElementsUI.fieldBorderWidth
        newStack.axis = .vertical
        newStack.arrangedSubviews.forEach { $0.alpha = 0 }
        bottomPinningContainerView.addPinnedSubview(newStack)
        bottomPinningContainerView.layoutIfNeeded()
        window?.rootViewController?.presentedViewController?.animateHeightChange {
            // Hack: Swap the dummy first view and real first view
            if let dummyFirstView = dummyFirstView,
               let firstView = self.views.first
            {
                self.stackView.insertArrangedSubview(dummyFirstView, at: 0)
                newStack.insertArrangedSubview(firstView, at: 0)
            }
            
            // Fade old out
            self.stackView.arrangedSubviews.forEach { $0.alpha = 0 }
            // Change height to accommodate new views
            self.bottomPinningContainerView.updateHeight()
            // Fade new in
            newStack.arrangedSubviews.forEach { $0.alpha = 1 }
            self.stackView = newStack
            self.views = newViews
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
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
        }
    }
}
