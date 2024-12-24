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

        update(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
}
