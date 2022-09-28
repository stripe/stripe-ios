//
//  AccountPickerLabelRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class AccountPickerLabelRowView: UIView {
    
    private lazy var topLevelHorizontalStackView: UIStackView = {
        let topLevelHorizontalStackView = UIStackView()
        topLevelHorizontalStackView.axis = .horizontal
        topLevelHorizontalStackView.spacing = 8
        topLevelHorizontalStackView.distribution = .fill
        topLevelHorizontalStackView.alignment = .center
        topLevelHorizontalStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return topLevelHorizontalStackView
    }()
    
    private lazy var labelStackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        labelStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return labelStackView
    }()
    
    private lazy var leadingTitleLabel: UILabel = {
        let leadingTitleLabel = UILabel()
        leadingTitleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        leadingTitleLabel.textColor = .textPrimary
        leadingTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leadingTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return leadingTitleLabel
    }()
    
    private lazy var trailingTitleLabel: UILabel = {
        let trailingTitleLabel = UILabel()
        trailingTitleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        trailingTitleLabel.textColor = .textPrimary
        trailingTitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return trailingTitleLabel
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .captionTightEmphasized)
        subtitleLabel.textColor = .textSecondary
        return subtitleLabel
    }()
    
    private var linkedView: UIView?

    init() {
        super.init(frame: .zero)
        labelStackView.addArrangedSubview({
            let horizontalStackView = UIStackView(
                arrangedSubviews: [
                    // we need a leading and a trailing
                    // title label because we want to
                    // prioritize the `trailingTitleLabel`
                    // when there's a need for truncation
                    leadingTitleLabel,
                    trailingTitleLabel,
                ]
            )
            horizontalStackView.axis = .horizontal
            horizontalStackView.spacing = 4
            return horizontalStackView
        }())
        
        topLevelHorizontalStackView.addArrangedSubview(labelStackView)
        addAndPinSubview(topLevelHorizontalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLeadingTitle(
        _ leadingTitle: String,
        trailingTitle: String?,
        subtitle: String?,
        isLinked: Bool
    ) {
        leadingTitleLabel.text = leadingTitle
        trailingTitleLabel.text = trailingTitle
        
        subtitleLabel.removeFromSuperview()
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            labelStackView.addArrangedSubview(subtitleLabel)
        }
        
        linkedView?.removeFromSuperview()
        linkedView = nil
        if isLinked {
            let linkedLabel = UILabel()
            linkedLabel.text = STPLocalizedString("Linked", "An indicator next to a bank account that educates the user that this bank account is already connected (or linked). This indicator appears in a screen that allows users to select which bank accounts they want to use to pay for something.")
            linkedLabel.font = .stripeFont(forTextStyle: .captionTightEmphasized)
            linkedLabel.textColor = .textSuccess
            linkedLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            linkedLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            // stack views make re-sizing and adding padding really easy
            // so we don't NEED a stack view for a single label but it
            // simplifies work
            let linkedLabelStackView = UIStackView(
                arrangedSubviews: [linkedLabel]
            )
            linkedLabelStackView.isLayoutMarginsRelativeArrangement = true
            linkedLabelStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 2,
                leading: 6,
                bottom: 2,
                trailing: 6
            )
            linkedLabelStackView.layer.cornerRadius = 4
            linkedLabelStackView.backgroundColor = .success100
            topLevelHorizontalStackView.addArrangedSubview(linkedLabelStackView)
            
            self.linkedView = linkedLabelStackView
        }
    }
}
