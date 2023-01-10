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

@available(iOSApplicationExtension, unavailable)
final class BulletPointLabelView: HitTestView {

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
            let primaryLabel = ClickableLabel(
                font: .stripeFont(forTextStyle: .body),
                boldFont: .stripeFont(forTextStyle: .bodyEmphasized),
                linkFont: .stripeFont(forTextStyle: .bodyEmphasized),
                textColor: .textPrimary
            )
            primaryLabel.setText(title, action: didSelectURL)
            verticalLabelStackView.addArrangedSubview(primaryLabel)
        }
        if let content = content {
            let displayingOnlyContent = (title == nil)
            let subtitleLabel = ClickableLabel(
                font: .stripeFont(forTextStyle: displayingOnlyContent ? .body : .detail),
                boldFont: .stripeFont(forTextStyle: displayingOnlyContent ? .bodyEmphasized : .detailEmphasized),
                linkFont: .stripeFont(forTextStyle: displayingOnlyContent ? .bodyEmphasized : .detailEmphasized),
                textColor: .textSecondary
            )
            subtitleLabel.setText(content, action: didSelectURL)
            verticalLabelStackView.addArrangedSubview(subtitleLabel)
        }
        addAndPinSubview(verticalLabelStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
