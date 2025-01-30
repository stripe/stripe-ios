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
            textColor: FinancialConnectionsAppearance.Colors.textCritical,
            linkColor: FinancialConnectionsAppearance.Colors.textCritical
        )
        errorLabel.setText(text)
        addAndPinSubview(errorLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
