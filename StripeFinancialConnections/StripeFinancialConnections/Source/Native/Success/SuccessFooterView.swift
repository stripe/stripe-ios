//
//  SuccessFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/15/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SuccessFooterView: UIView {

    private let didSelectDone: (SuccessFooterView) -> Void

    private lazy var doneButton: Button = {
        let doneButton = Button(configuration: .financialConnectionsPrimary)
        doneButton.title = "Done"  // TODO: replace with UIButton.doneButtonTitle once the SDK is localized
        doneButton.addTarget(self, action: #selector(didSelectDoneButton), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        doneButton.accessibilityIdentifier = "success_done_button"
        return doneButton
    }()

    init(
        showFailedToLinkNotice: Bool,
        businessName: String?,
        didSelectDone: @escaping (SuccessFooterView) -> Void
    ) {
        self.didSelectDone = didSelectDone
        super.init(frame: .zero)

        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 24

        if showFailedToLinkNotice {
            let saveToLinkFailedNoticeView = CreateSaveToLinkFailedNoticeView(
                businessName: businessName
            )
            footerStackView.addArrangedSubview(saveToLinkFailedNoticeView)
        }
        footerStackView.addArrangedSubview(doneButton)
        addAndPinSubviewToSafeArea(footerStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectDoneButton() {
        didSelectDone(self)
    }

    func setIsLoading(_ isLoading: Bool) {
        doneButton.isLoading = isLoading
    }
}

private func CreateSaveToLinkFailedNoticeView(
    businessName: String?
) -> UIView {
    let errorLabelFont = FinancialConnectionsFont.label(.smallEmphasized)
    let warningIconWidthAndHeight: CGFloat = 12
    let warningIconInsets = errorLabelFont.topPadding
    let warningIconImageView = UIImageView()
    warningIconImageView.image = Image.warning_triangle.makeImage()
        .withTintColor(.textCritical)
        // Align the icon to the center of the first line.
        //
        // UIStackView does not do a great job of doing this
        // automatically.
        .withAlignmentRectInsets(
            UIEdgeInsets(top: -warningIconInsets, left: 0, bottom: warningIconInsets, right: 0)
        )
    warningIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        warningIconImageView.widthAnchor.constraint(equalToConstant: warningIconWidthAndHeight),
        warningIconImageView.heightAnchor.constraint(equalToConstant: warningIconWidthAndHeight),
    ])

    let errorLabel = AttributedLabel(
        font: .label(.smallEmphasized),
        textColor: .textPrimary
    )
    errorLabel.numberOfLines = 0
    errorLabel.text = {
        if let businessName = businessName {
            return String(format: STPLocalizedString("Your account was connected to %@ but could not be saved to Link at this time.", "A warning message that explains the user that their bank account was successfully connected for payments, but it was not connected to Stripe's Link network. '%@' will be replaced by the business name, ex. Cola Cola Inc."), businessName)
        } else {
            return STPLocalizedString("Your account was connected but could not be saved to Link at this time.", "A warning message that explains the user that their bank account was successfully connected for payments, but it was not connected to Stripe's Link network.")
        }
    }()
    errorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

    let horizontalStackView = HitTestStackView(
        arrangedSubviews: [
            warningIconImageView,
            errorLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.alignment = .top
    horizontalStackView.spacing = 8
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 10,
        leading: 12,
        bottom: 10,
        trailing: 12
    )
    horizontalStackView.backgroundColor = .attention50
    horizontalStackView.layer.cornerRadius = 8
    return horizontalStackView
}
