//
//  ExpandableDetailView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/20/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// A view that displays a caption label with an optional expandable detail section.
///
/// Add as an arranged subview to a stack view. Update content via
/// `update(caption:detail:)` and toggle expansion via `toggleExpansion()`.
final class ExpandableDetailView: UIView {

    private let selectorAppearance: TwoOptionSelectorViewAppearance
    private let captionLabel = TappableAttributedLabel()
    private let expandedContentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = true
        label.alpha = 0
        label.clipsToBounds = true
        return label
    }()

    private var currentCaption: String?
    private var detail: String?
    private var isExpanded = false
    private var isAnimating = false
    private var detailHeightConstraint: NSLayoutConstraint?

    init(appearance: TwoOptionSelectorViewAppearance) {
        self.selectorAppearance = appearance
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        let baseFont = selectorAppearance.scaledFont(for: selectorAppearance.font, style: .caption1)

        captionLabel.font = baseFont
        captionLabel.textColor = selectorAppearance.captionColor
        captionLabel.numberOfLines = 0
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(captionLabel)

        expandedContentLabel.font = baseFont
        expandedContentLabel.textColor = selectorAppearance.captionColor
        expandedContentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(expandedContentLabel)

        detailHeightConstraint = expandedContentLabel.heightAnchor.constraint(equalToConstant: 0)
        detailHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: topAnchor),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            expandedContentLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            expandedContentLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            expandedContentLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            expandedContentLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        setHiddenIfNecessary(true)
    }

    // MARK: - Internal

    func update(caption: String?, detail: String?) {
        self.currentCaption = caption
        self.detail = detail

        guard let caption, !caption.isEmpty else {
            setHiddenIfNecessary(true)
            expandedContentLabel.text = nil
            collapse()
            return
        }

        setHiddenIfNecessary(false)

        if let detail, !detail.isEmpty {
            rebuildCaptionLabelText()
            expandedContentLabel.text = detail
        } else {
            captionLabel.setText(
                caption,
                baseFont: selectorAppearance.scaledFont(for: selectorAppearance.font, style: .caption1),
                baseColor: selectorAppearance.captionColor,
                highlights: []
            )
            expandedContentLabel.text = nil
            collapse()
        }
    }

    func toggleExpansion() {
        guard !isAnimating else { return }
        guard let detail, !detail.isEmpty else { return }
        isExpanded.toggle()
        rebuildCaptionLabelText()

        let layoutContainer = Self.layoutAnimationContainer(for: self)
        let targetHeight = expandedDetailHeight()

        if isExpanded {
            detailHeightConstraint?.constant = 0
            expandedContentLabel.setHiddenIfNecessary(false)
            expandedContentLabel.alpha = 0
            invalidateLayoutUpHierarchy()
            layoutContainer.layoutIfNeeded()
        } else {
            detailHeightConstraint?.constant = expandedContentLabel.bounds.height
            invalidateLayoutUpHierarchy()
            layoutContainer.layoutIfNeeded()
        }

        isAnimating = true
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.detailHeightConstraint?.constant = self.isExpanded ? targetHeight : 0
            self.expandedContentLabel.alpha = self.isExpanded ? 1.0 : 0.0
            self.invalidateLayoutUpHierarchy()
            layoutContainer.layoutIfNeeded()
        } completion: { _ in
            self.isAnimating = false
            UIAccessibility.post(notification: .layoutChanged, argument: self.captionLabel)
        }
    }

    // MARK: - Private

    private func rebuildCaptionLabelText() {
        guard let caption = currentCaption else { return }
        let toggleText = isExpanded ? String.Localized.hideDetails : String.Localized.showDetails
        let fullText = "\(caption) \(toggleText)"
        let baseFont = selectorAppearance.scaledFont(for: selectorAppearance.font, style: .caption1)

        captionLabel.setText(
            fullText,
            baseFont: baseFont,
            baseColor: selectorAppearance.captionColor,
            highlights: [
                TappableAttributedLabel.TappableHighlight(
                    text: toggleText,
                    font: nil,
                    color: nil,
                    action: { [weak self] in self?.toggleExpansion() }
                ),
            ]
        )

        guard let attrText = captionLabel.attributedText else { return }
        let mutable = NSMutableAttributedString(attributedString: attrText)
        let range = (fullText as NSString).range(of: toggleText)
        if range.location != NSNotFound {
            mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        captionLabel.attributedText = mutable
    }

    private func collapse() {
        guard isExpanded || !expandedContentLabel.isHidden else { return }
        isExpanded = false
        detailHeightConstraint?.constant = 0
        expandedContentLabel.setHiddenIfNecessary(true)
        expandedContentLabel.alpha = 0
        invalidateLayoutUpHierarchy()
    }

    private func expandedDetailHeight() -> CGFloat {
        let fittingWidth = max(expandedContentLabel.bounds.width, bounds.width)
        guard fittingWidth > 0 else {
            return expandedContentLabel.intrinsicContentSize.height
        }
        return ceil(expandedContentLabel.sizeThatFits(CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)).height)
    }

    private func invalidateLayoutUpHierarchy() {
        var view: UIView? = self
        while let current = view {
            current.invalidateIntrinsicContentSize()
            current.setNeedsLayout()
            view = current.superview as? UIView
        }
    }

    private static func layoutAnimationContainer(for view: UIView) -> UIView {
        var container = view
        while let superview = container.superview as? UIView, !(superview is UIWindow) {
            container = superview
        }
        return container
    }
}
