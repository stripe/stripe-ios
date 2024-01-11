//
//  ManualEntryErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/31/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class ManualEntryErrorView: UIView {

    init(text: String) {
        super.init(frame: .zero)
        let errorLabel = AttributedTextView(
            font: .label(.small),
            boldFont: .label(.smallEmphasized),
            linkFont: .label(.small),
            textColor: .textFeedbackCritical,
            linkColor: .textFeedbackCritical
        )
        errorLabel.setText(text)
        errorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                errorLabel,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 6
        // align icon + text to the top
        horizontalStackView.alignment = .top
        addAndPinSubview(horizontalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
