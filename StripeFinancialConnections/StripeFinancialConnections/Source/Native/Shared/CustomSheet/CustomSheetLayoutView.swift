//
//  CustomSheetLayoutView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/5/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// Reusable view that separates sheets into two parts:
/// 1. A scroll view for content
/// 2. A footer that is "locked" and does not get affected by scroll view
///
/// Purposefully NOT a `UIView` subclass because it should only be used via
/// `addToView` helper function.
final class CustomSheetLayoutView {

    private weak var scrollViewContentView: UIView?
    private let paneLayoutView: UIView
    let scrollView: UIScrollView

    init(contentView: UIView, footerView: UIView?) {
        self.scrollViewContentView = contentView

        let scrollView = ResizableScrollView()
        self.scrollView = scrollView
        scrollView.addAndPinSubview(contentView)

        let verticalStackView = HitTestStackView(
            arrangedSubviews: [
                CreateHandleView(),
                scrollView,
            ]
        )
        verticalStackView.spacing = 0
        verticalStackView.axis = .vertical

        if let footerView = footerView {
            verticalStackView.addArrangedSubview(footerView)
        }

        self.paneLayoutView = verticalStackView
    }

    func addTo(view: UIView) {
        // this function encapsulates an error-prone sequence where we
        // must add `paneLayoutView` (and all it's subviews) to the `view`
        // BEFORE we can add a constraint for `UIScrollView` content
        view.addAndPinSubviewToSafeArea(paneLayoutView)
        scrollViewContentView?.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
    }
}

private final class ResizableScrollView: UIScrollView {

    private var lastContentSize: CGSize?

    override var intrinsicContentSize: CGSize {
        return contentSize
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // this code is here to prevent accidental infinite loops
        // from calling `invalidateIntrinsicContentSize` in `layoutSubviews`
        let lastContentSize = lastContentSize ?? .zero
        if
            superview != nil,
            (floor(lastContentSize.width) != floor(contentSize.width)) || (floor(lastContentSize.height) != floor(contentSize.height))
        {
            self.lastContentSize = contentSize
            invalidateIntrinsicContentSize()
        }
    }
}

private func CreateHandleView() -> UIView {
    let topPadding: CGFloat = 12
    let bottomPadding: CGFloat = 8
    let handleHeight: CGFloat = 4

    let containerView = UIView()
    containerView.backgroundColor = .clear
    containerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        containerView.heightAnchor.constraint(equalToConstant: topPadding + handleHeight + bottomPadding),
    ])

    let handleView = UIView()
    handleView.backgroundColor = UIColor.textDisabled // TODO(kgaidis): fix color
    handleView.layer.cornerRadius = 4
    containerView.addSubview(handleView)
    handleView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        handleView.widthAnchor.constraint(equalToConstant: 32),
        handleView.heightAnchor.constraint(equalToConstant: handleHeight),
        handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
        handleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottomPadding),
    ])
    return containerView
}
