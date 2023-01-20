//
//  InstitutionSearchErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/21/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchErrorView: UIView {

    init(didSelectEnterYourBankDetailsManually: (() -> Void)?) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateIconView(),
                CreateLabelView(
                    didSelectEnterYourBankDetailsManually: didSelectEnterYourBankDetailsManually
                ),
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
    iconImageView.image = Image.warning_triangle.makeImage()
        .withTintColor(.textSecondary)
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
    titleLabel.text = STPLocalizedString(
        "Search is currently unavailable",
        "The title of an error message that appears when a user searches for a bank, but there's an issue, or error."
    )
    return titleLabel
}

@available(iOSApplicationExtension, unavailable)
private func CreateSubtitleLabel(
    didSelectEnterYourBankDetailsManually: (() -> Void)?
) -> UIView {
    let subtitleLabel = ClickableLabel(
        font: .stripeFont(forTextStyle: .caption),
        boldFont: .stripeFont(forTextStyle: .captionEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionEmphasized),
        textColor: .textSecondary,
        alignCenter: true
    )
    if let didSelectEnterYourBankDetailsManually = didSelectEnterYourBankDetailsManually {
        let pleaseTryAgainLaterString = STPLocalizedString(
            "Please try again later or %@.",
            "Part of the subtitle of an error message that appears when a user searches for a bank, but there's an issue, or error. It instructs the user to try searching again later. '%@' will be replaced by 'enter your bank details manually' to form 'Please try again later or enter your bank details manually.'."
        )
        let enterYourBankDetailsManuallyString = STPLocalizedString(
            "enter your bank details manually",
            "Part of the subtitle of an error message that appears when a user searches for a bank, but there's an issue, or error. This 'part' will be placed into a full string that says 'Please try again later or enter your bank details manually.'"
        )
        subtitleLabel.setText(
            String(
                format: pleaseTryAgainLaterString,
                "[\(enterYourBankDetailsManuallyString)](https://www.use-action-instead.com)"
            ),
            action: { _ in
                didSelectEnterYourBankDetailsManually()
            }
        )
    } else {
        subtitleLabel.setText(
            STPLocalizedString(
                "Please try again later.",
                "The subtitle of an error message that appears when a user searches for a bank, but there's an issue, or error. It instructs the user to try searching again later."
            )
        )
    }
    return subtitleLabel
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct InstitutionSearchErrorViewUIViewRepresentable: UIViewRepresentable {

    let didSelectEnterYourBankDetailsManually: (() -> Void)?

    func makeUIView(context: Context) -> InstitutionSearchErrorView {
        InstitutionSearchErrorView(
            didSelectEnterYourBankDetailsManually: didSelectEnterYourBankDetailsManually
        )
    }

    func updateUIView(_ uiView: InstitutionSearchErrorView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct InstitutionSearchErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 50) {
            InstitutionSearchErrorViewUIViewRepresentable(didSelectEnterYourBankDetailsManually: {})
                .frame(maxHeight: 80)
            InstitutionSearchErrorViewUIViewRepresentable(didSelectEnterYourBankDetailsManually: nil)
                .frame(maxHeight: 80)
            Spacer()
        }
        .padding()
    }
}

#endif
