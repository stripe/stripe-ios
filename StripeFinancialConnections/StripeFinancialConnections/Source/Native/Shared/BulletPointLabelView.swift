//
//  BulletPointLabelView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class BulletPointLabelView: HitTestView {

    private(set) var topPadding: CGFloat = 0
    private(set) var topLineHeight: CGFloat = 0

    init(
        title: String?,
        content: String?,
        didSelectURL: @escaping (URL) -> Void
    ) {
        super.init(frame: .zero)
        let verticalLabelStackView = HitTestStackView()
        verticalLabelStackView.axis = .vertical
        verticalLabelStackView.spacing = 2
        if let title = title {
            let font: FinancialConnectionsFont = .body(.medium)
            let primaryLabel = AttributedTextView(
                font: font,
                boldFont: .body(.mediumEmphasized),
                linkFont: .body(.mediumEmphasized),
                textColor: .textPrimary
            )
            primaryLabel.setText(title, action: didSelectURL)
            verticalLabelStackView.addArrangedSubview(primaryLabel)
            topPadding = font.topPadding
            topLineHeight = font.lineHeight
        }
        if let content = content {
            let displayingOnlyContent = (title == nil)
            let font: FinancialConnectionsFont = displayingOnlyContent ? .body(.medium) : .body(.small)
            let subtitleLabel = AttributedTextView(
                font: font,
                boldFont: displayingOnlyContent ? .body(.mediumEmphasized) : .body(.smallEmphasized),
                linkFont: displayingOnlyContent ? .body(.mediumEmphasized) : .body(.smallEmphasized),
                textColor: .textSecondary
            )
            subtitleLabel.setText(content, action: didSelectURL)
            verticalLabelStackView.addArrangedSubview(subtitleLabel)
            if displayingOnlyContent {
                topPadding = font.topPadding
                topLineHeight = font.lineHeight
            }
        }
        addAndPinSubview(verticalLabelStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
