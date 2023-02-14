//
//  AccountPickerLabelRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/8/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

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
        leadingTitleLabel.lineBreakMode = .byCharWrapping
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

    init() {
        super.init(frame: .zero)
        labelStackView.addArrangedSubview(
            {
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
            }()
        )

        topLevelHorizontalStackView.addArrangedSubview(labelStackView)
        addAndPinSubview(topLevelHorizontalStackView)
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
