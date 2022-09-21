//
//  InstitutionSearchErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/21/22.
//

import Foundation
import UIKit

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchErrorView: UIView {
    
    init(didSelectEnterYourBankDetailsManually: (() -> Void)?) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateIconView(),
                CreateLabelView(didSelectEnterYourBankDetailsManually: didSelectEnterYourBankDetailsManually),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 8
        verticalStackView.alignment = .center
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
private func CreateIconView() -> UIView {
    let iconImageView = UIImageView()
    if #available(iOSApplicationExtension 13.0, *) {
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
    }
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconImageView.widthAnchor.constraint(equalToConstant: 24),
        iconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    return iconImageView
}

@available(iOSApplicationExtension, unavailable)
private func CreateLabelView(
    didSelectEnterYourBankDetailsManually: (() -> Void)?
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            CreateTitleLabel(),
            CreateSubtitleLabel(
                didSelectEnterYourBankDetailsManually: didSelectEnterYourBankDetailsManually
            ),
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 4
    verticalStackView.alignment = .center
    return verticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateTitleLabel() -> UIView {
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .captionEmphasized)
    titleLabel.textColor = .textSecondary
    titleLabel.textAlignment = .center
    titleLabel.text = "Search is currently unavailable"
    return titleLabel
}

@available(iOSApplicationExtension, unavailable)
private func CreateSubtitleLabel(
    didSelectEnterYourBankDetailsManually: (() -> Void)?
) -> UIView {
    let subtitleLabel = ClickableLabel()
    if let didSelectEnterYourBankDetailsManually = didSelectEnterYourBankDetailsManually {
        subtitleLabel.setText(
            "Please try again later or [enter your bank details manually](https://www.use-action-instead.com).",
            font: .stripeFont(forTextStyle: .captionEmphasized),
            linkFont: .stripeFont(forTextStyle: .captionEmphasized),
            textColor: .textSecondary,
            alignCenter: true,
            action: { _ in
                didSelectEnterYourBankDetailsManually()
            }
        )
    } else {
        subtitleLabel.setText(
            "Please try again later.",
            font: .stripeFont(forTextStyle: .captionEmphasized),
            linkFont: .stripeFont(forTextStyle: .captionEmphasized),
            textColor: .textSecondary,
            alignCenter: true
        )
    }
    return subtitleLabel
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct InstitutionSearchErrorViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> InstitutionSearchErrorView {
        InstitutionSearchErrorView(didSelectEnterYourBankDetailsManually: {})
    }
    
    func updateUIView(_ uiView: InstitutionSearchErrorView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct InstitutionSearchErrorView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                InstitutionSearchErrorViewUIViewRepresentable()
                    .frame(maxHeight: 80)
                Spacer()
            }
            .padding()
        }
    }
}

#endif
