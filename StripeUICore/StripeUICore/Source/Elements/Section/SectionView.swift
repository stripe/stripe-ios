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

    // MARK: - Border properties
    private var borderLayer = CAShapeLayer()
    private var currentBorderWidth: CGFloat = 0
    private var currentBorderColor: CGColor?

    // MARK: - Initializers

    init(viewModel: SectionViewModel) {
        self.viewModel = viewModel
        self.containerView = SectionContainerView(views: viewModel.views, theme: viewModel.theme)
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [titleLabel, containerView, errorOrSubLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.setCustomSpacing(8, after: containerView)
        addAndPinSubview(stack)

        // Setup border layer
        setupBorderLayer()

        update(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Border handling with UIBezierPath

    private func setupBorderLayer() {
        containerView.layer.borderWidth = 0

        borderLayer.fillColor = nil
        borderLayer.lineCap = .round
        borderLayer.lineJoin = .round

        containerView.layer.addSublayer(borderLayer)
        applyDefaultBorder()
    }

    private func updateBorderPath() {
        // Use a bezier path for borders for smoother corners.
        DispatchQueue.main.async {
            let bounds = self.containerView.bounds
            let cornerRadius = self.containerView.layer.cornerRadius

            let inset = self.currentBorderWidth / 2.0
            let borderRect = bounds.insetBy(dx: inset, dy: inset)

            let bezierPath = UIBezierPath(roundedRect: borderRect, cornerRadius: cornerRadius)
            self.borderLayer.path = bezierPath.cgPath
            self.borderLayer.lineWidth = self.currentBorderWidth
            self.borderLayer.frame = bounds
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorderPath()
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

    private func applyDefaultBorder() {
        currentBorderWidth = viewModel.theme.borderWidth
        currentBorderColor = viewModel.theme.colors.border.cgColor

        borderLayer.strokeColor = currentBorderColor
        updateBorderPath()
    }

    private func applyHighlightedBorder(with configuration: HighlightBorderConfiguration) {
        currentBorderWidth = configuration.width
        currentBorderColor = configuration.color.cgColor

        borderLayer.strokeColor = currentBorderColor
        updateBorderPath()
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if isHighlighted, case .highlightBorder(let configuration) = viewModel.selectionBehavior {
            currentBorderColor = configuration.color.cgColor
        } else {
            currentBorderColor = viewModel.theme.colors.border.cgColor
        }

        borderLayer.strokeColor = currentBorderColor
        updateBorderPath()
    }
#endif
}
