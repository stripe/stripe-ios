//
//  SectionView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

typealias SectionViewModel = SectionElement.ViewModel

/// For internal SDK use only
@objc(STP_Internal_SectionView)
final class SectionView: UIView {

    // MARK: - Views

    lazy var errorOrSubLabel: UILabel = {
        return ElementsUI.makeErrorLabel(theme: viewModel.theme)
    }()
    let containerView: SectionContainerView
    lazy var titleLabel: UILabel = {
        return ElementsUI.makeSectionTitleLabel(theme: viewModel.theme)
    }()

    let viewModel: SectionViewModel
    private var isHighlighted = false

    private lazy var selectedBorderLayer = CAShapeLayer()

    // MARK: - Initializers

    init(viewModel: SectionViewModel) {
        self.viewModel = viewModel
        self.containerView = SectionContainerView(views: viewModel.views, theme: viewModel.theme)
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [titleLabel, containerView, errorOrSubLabel])
        stack.axis = .vertical
        stack.spacing = ElementsUI.sectionElementInternalSpacing
        addAndPinSubview(stack)

        setupBorderLayer()
        update(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Border handling

    private func setupBorderLayer() {
        selectedBorderLayer.fillColor = nil
        selectedBorderLayer.lineCap = .round
        selectedBorderLayer.lineJoin = .round
    }

    private func updateBorderPath() {
        let bounds = containerView.bounds
        let cornerRadius = containerView.layer.cornerRadius

        let borderWidth = selectedBorderLayer.lineWidth
        let inset = borderWidth / 2.0
        let borderRect = bounds.insetBy(dx: inset, dy: inset)

        let bezierPath = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius)
        selectedBorderLayer.path = bezierPath.cgPath
        selectedBorderLayer.frame = bounds
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isHighlighted {
            updateBorderPath()
        }
    }

    // MARK: - Private methods

    func update(with viewModel: SectionViewModel) {
        isHidden = viewModel.views.filter({ !$0.isHidden }).isEmpty
        guard !isHidden else {
            return
        }
        containerView.updateUI(newViews: viewModel.views)
        titleLabel.text = viewModel.title
        titleLabel.isHidden = viewModel.title == nil
        if let errorText = viewModel.errorText, !errorText.isEmpty {
            errorOrSubLabel.text = viewModel.errorText
            errorOrSubLabel.isHidden = false
            errorOrSubLabel.textColor = viewModel.theme.colors.danger
        } else if let subLabel = viewModel.subLabel {
            errorOrSubLabel.text = subLabel
            errorOrSubLabel.isHidden = false
            errorOrSubLabel.textColor = viewModel.theme.colors.secondaryText
        } else {
            errorOrSubLabel.text = nil
            errorOrSubLabel.isHidden = true
        }
    }

    func updateBorder(for element: Element) {
        guard case .highlightBorder(let configuration) = viewModel.selectionBehavior else {
            return
        }

        let isEditing: Bool = {
            switch element {
            case let textField as TextFieldElement:
                return textField.isEditing
            case let dropdown as DropdownFieldElement:
                return dropdown.isEditing
            default:
                return false
            }
        }()
        self.isHighlighted = isEditing

        let borderChanges = {
            if isEditing {
                self.applyHighlightedBorder(with: configuration)
            } else {
                self.applyDefaultBorder()
            }
        }

        configuration.animator.addAnimations(borderChanges)
        configuration.animator.startAnimation()
    }

    // For "default" borders, use standard `CALayer` borders.
    private func applyDefaultBorder() {
        selectedBorderLayer.removeFromSuperlayer()

        containerView.layer.borderWidth = viewModel.theme.borderWidth
        containerView.layer.borderColor = viewModel.theme.colors.border.cgColor
    }

    // For highlighted borders, apply a custom `UIBezierPath` border for smoother corners.
    private func applyHighlightedBorder(with configuration: HighlightBorderConfiguration) {
        containerView.layer.borderWidth = 0
        containerView.layer.cornerRadius = configuration.cornerRadius

        selectedBorderLayer.strokeColor = configuration.color.cgColor
        selectedBorderLayer.lineWidth = configuration.width
        selectedBorderLayer.cornerRadius = configuration.cornerRadius

        if selectedBorderLayer.superlayer != containerView.layer {
            containerView.layer.addSublayer(selectedBorderLayer)
        }

        updateBorderPath()
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        if isHighlighted, case .highlightBorder(let configuration) = viewModel.selectionBehavior {
            selectedBorderLayer.strokeColor = configuration.color.cgColor
        } else {
            containerView.layer.borderColor = viewModel.theme.colors.border.cgColor
        }
    }
#endif
}
