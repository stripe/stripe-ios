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
    
    private lazy var leadingTitleLabel: UILabel = {
        let leadingTitleLabel = UILabel()
        leadingTitleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        leadingTitleLabel.textColor = .textSecondary
        leadingTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leadingTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return leadingTitleLabel
    }()
    
    private lazy var trailingTitleLabel: UILabel = {
        let trailingTitleLabel = UILabel()
        trailingTitleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        trailingTitleLabel.textColor = .textSecondary
        trailingTitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return trailingTitleLabel
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .captionTightEmphasized)
        subtitleLabel.textColor = .textSecondary
        return subtitleLabel
    }()
    
    private lazy var labelStackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        return labelStackView
    }()
    
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
        addAndPinSubview(labelStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLeadingTitle(
        _ leadingTitle: String,
        trailingTitle: String?,
        subtitle: String?
    ) {
        leadingTitleLabel.text = leadingTitle
        trailingTitleLabel.text = trailingTitle
        
        subtitleLabel.removeFromSuperview()
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            labelStackView.addArrangedSubview(subtitleLabel)
        }
    }
}
