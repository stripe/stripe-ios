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

final class SectionView: UIView {
    
    // MARK: - Views
    
    lazy var errorLabel: UILabel = {
        let error = ElementsUI.makeErrorLabel()
        return error
    }()
    let containerView: SectionContainerView

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = ElementsUI.sectionTitleFont
        label.textColor = CompatibleColor.secondaryLabel
        label.accessibilityTraits = [.header]
        return label
    }()
    
    // MARK: - Initializers
    
    init(viewModel: SectionViewModel) {
        self.containerView = SectionContainerView(views: viewModel.views)
        super.init(frame: .zero)

        let stack = UIStackView(arrangedSubviews: [titleLabel, containerView, errorLabel])
        stack.axis = .vertical
        stack.spacing = 4
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
        if let error = viewModel.error, !error.isEmpty {
            errorLabel.text = viewModel.error
            errorLabel.isHidden = false
        } else {
            errorLabel.text = nil
            errorLabel.isHidden = true
        }
        
    }
}


