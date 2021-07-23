//
//  DynamicHeightContainerView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 7/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

class DynamicHeightContainerView: UIView {
    enum PinnedDirection {
        case top, bottom
    }
    let pinnedDirection: PinnedDirection
    private var pinnedDirectionConstraint: NSLayoutConstraint? = nil
    
    // MARK: - Initializers

    required init(pinnedDirection: PinnedDirection = .bottom) {
        self.pinnedDirection = pinnedDirection
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Internal methods

    /// Adds a subview and pins it to the top or bottom. It leaves the other end unpinned, thus not affecting the view's height.
    func addPinnedSubview(_ view: UIView) {
        // Add new view
        view.translatesAutoresizingMaskIntoConstraints = false
        super.addSubview(view)
        let pinnedDirectionAnchor: NSLayoutConstraint = {
            switch pinnedDirection {
            case .top:
                return view.topAnchor.constraint(equalTo: topAnchor)
            case .bottom:
                return view.bottomAnchor.constraint(equalTo: bottomAnchor)
            }
        }()

        NSLayoutConstraint.activate([
            pinnedDirectionAnchor,
            view.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            view.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
        ])
    }

    /// Changes the view's height to be equal to the last added subview's height.
    func updateHeight() {
        guard let mostRecentlyAddedView = subviews.last else {
            return
        }
        // Deactivate old constraint
        pinnedDirectionConstraint?.isActive = false

        // Activate the new constraint
        pinnedDirectionConstraint = {
            switch pinnedDirection {
            case .top:
                return bottomAnchor.constraint(equalTo: mostRecentlyAddedView.bottomAnchor)
            case .bottom:
                return topAnchor.constraint(equalTo: mostRecentlyAddedView.topAnchor)
            }
        }()
        pinnedDirectionConstraint?.isActive = true
    }
}
