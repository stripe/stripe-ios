//
//  DynamicHeightContainerView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// For internal SDK use only
@objc(STP_Internal_DynamicHeightContainerView)
@_spi(STP) public class DynamicHeightContainerView: UIView {
    @frozen public enum PinnedDirection {
        case top, bottom
    }
    let pinnedDirection: PinnedDirection
    private var pinnedDirectionConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    public required init(pinnedDirection: PinnedDirection = .bottom) {
        self.pinnedDirection = pinnedDirection
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal methods

    /// Adds a subview and pins it to the top or bottom. It leaves the other end unpinned, thus not affecting the view's height.
    public func addPinnedSubview(_ view: UIView) {
        #if canImport(AppKit) && !canImport(UIKit)
        view.translatesAutoresizingMaskIntoConstraints = true
        super.addSubview(view)
        needsLayout = true
        invalidateIntrinsicContentSize()
        #else
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
        #endif
    }

    /// Changes the view's height to be equal to the last added subview's height.
    public func updateHeight() {
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

    #if canImport(AppKit) && !canImport(UIKit)
    public override var intrinsicContentSize: CGSize {
        guard let view = subviews.last else {
            return .zero
        }
        let size = view.intrinsicContentSize
        if size.height > 0 {
            return size
        }
        let childSizes = view.subviews.map(\.intrinsicContentSize).filter { $0.height > 0 }
        guard !childSizes.isEmpty else {
            return size
        }
        return CGSize(
            width: childSizes.map(\.width).max() ?? size.width,
            height: childSizes.map(\.height).max() ?? size.height
        )
    }

    public override func layout() {
        super.layout()
        guard let view = subviews.last else {
            return
        }
        let margins = layoutMargins
        view.frame = CGRect(
            x: margins.left,
            y: margins.top,
            width: max(0, bounds.width - margins.left - margins.right),
            height: max(0, bounds.height - margins.top - margins.bottom)
        )
    }
    #endif
}
