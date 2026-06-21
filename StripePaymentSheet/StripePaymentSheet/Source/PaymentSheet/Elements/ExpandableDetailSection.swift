//
//  ExpandableDetailSection.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/20/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Encapsulates a caption label with an optional expandable detail section.
///
/// Owns the caption label, detail label, expansion state, height constraint,
/// and animation logic. Install into a stack view via `install(in:)` and
/// update content via `update(caption:expandableContent:in:)`.
final class ExpandableDetailSection {

    private let appearance: TwoOptionSelectorViewAppearance
    private let captionLabel = TappableAttributedLabel()
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = true
        label.alpha = 0
        label.clipsToBounds = true
        return label
    }()

    private var currentCaption: String?
    private var expandableContent: String?
    private var isExpanded = false
    private var heightConstraint: NSLayoutConstraint?

    init(appearance: TwoOptionSelectorViewAppearance) {
        self.appearance = appearance
    }

    func install(in stackView: UIStackView) {
        let baseFont = appearance.scaledFont(for: appearance.font, style: .caption1)
        captionLabel.font = baseFont
        captionLabel.textColor = appearance.captionColor
        captionLabel.numberOfLines = 0
        captionLabel.isHidden = true
        stackView.addArrangedSubview(captionLabel)

        detailLabel.font = baseFont
        detailLabel.textColor = appearance.captionColor
        stackView.addArrangedSubview(detailLabel)
        heightConstraint = detailLabel.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    func update(caption: String?, expandableContent: String?, in hostView: UIView) {
        self.currentCaption = caption
        self.expandableContent = expandableContent

        guard let caption, !caption.isEmpty else {
            captionLabel.isHidden = true
            detailLabel.text = nil
            collapse(in: hostView)
            return
        }

        captionLabel.isHidden = false

        if let expandableContent, !expandableContent.isEmpty {
            rebuildCaptionWithToggle(in: hostView)
            detailLabel.text = expandableContent
        } else {
            captionLabel.setText(
                caption,
                baseFont: appearance.scaledFont(for: appearance.font, style: .caption1),
                baseColor: appearance.captionColor,
                highlights: []
            )
            detailLabel.text = nil
            collapse(in: hostView)
        }
    }

    // MARK: - Private

    private func rebuildCaptionWithToggle(in hostView: UIView) {
        guard let caption = currentCaption else { return }
        let toggleText = isExpanded ? String.Localized.hideDetails : String.Localized.showDetails
        let fullText = "\(caption) \(toggleText)"
        let baseFont = appearance.scaledFont(for: appearance.font, style: .caption1)

        captionLabel.setText(
            fullText,
            baseFont: baseFont,
            baseColor: appearance.captionColor,
            highlights: [
                TappableAttributedLabel.TappableHighlight(
                    text: toggleText,
                    font: nil,
                    color: nil,
                    action: { [weak self, weak hostView] in
                        guard let self, let hostView else { return }
                        self.toggle(in: hostView)
                    }
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

    func toggle(in hostView: UIView) {
        guard let expandableContent, !expandableContent.isEmpty else { return }
        isExpanded.toggle()
        rebuildCaptionWithToggle(in: hostView)

        let layoutContainer = Self.layoutAnimationContainer(for: hostView)
        let targetHeight = expandedHeight(in: hostView)

        if isExpanded {
            heightConstraint?.constant = 0
            detailLabel.setHiddenIfNecessary(false)
            detailLabel.alpha = 0
            Self.invalidateIntrinsicContentSizeUpHierarchy(from: hostView)
            layoutContainer.layoutIfNeeded()
        } else {
            heightConstraint?.constant = detailLabel.bounds.height
            Self.invalidateIntrinsicContentSizeUpHierarchy(from: hostView)
            layoutContainer.layoutIfNeeded()
        }

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: .curveEaseInOut
        ) {
            self.heightConstraint?.constant = self.isExpanded ? targetHeight : 0
            self.detailLabel.alpha = self.isExpanded ? 1.0 : 0.0
            Self.invalidateIntrinsicContentSizeUpHierarchy(from: hostView)
            layoutContainer.layoutIfNeeded()
        } completion: { _ in
            UIAccessibility.post(notification: .layoutChanged, argument: self.captionLabel)
        }
    }

    private func collapse(in hostView: UIView) {
        guard isExpanded || !detailLabel.isHidden else { return }
        isExpanded = false
        heightConstraint?.constant = 0
        detailLabel.setHiddenIfNecessary(true)
        detailLabel.alpha = 0
        Self.invalidateIntrinsicContentSizeUpHierarchy(from: hostView)
    }

    private func expandedHeight(in hostView: UIView) -> CGFloat {
        let fittingWidth = max(detailLabel.bounds.width, hostView.bounds.width)
        guard fittingWidth > 0 else {
            return detailLabel.intrinsicContentSize.height
        }
        return ceil(detailLabel.sizeThatFits(CGSize(width: fittingWidth, height: .greatestFiniteMagnitude)).height)
    }

    private static func invalidateIntrinsicContentSizeUpHierarchy(from view: UIView) {
        var current: UIView? = view
        while let v = current {
            v.invalidateIntrinsicContentSize()
            v.setNeedsLayout()
            current = v.superview
        }
    }

    private static func layoutAnimationContainer(for view: UIView) -> UIView {
        var container = view
        while let superview = container.superview, !(superview is UIWindow) {
            container = superview
        }
        return container
    }
}
