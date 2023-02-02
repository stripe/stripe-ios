//
//  InstitutionSearchFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/19/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchFooterView: UIView {

    init(didSelectManuallyAddYourAccount: (() -> Void)?) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateTitleLabel()
                // ...more views are added later...
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20,
            leading: 24,
            bottom: 20,
            trailing: 24
        )
        verticalStackView.backgroundColor = .backgroundContainer
        verticalStackView.addArrangedSubview(
            CreateRowView(
                image: .check,
                title: STPLocalizedString(
                    "Double check your spelling and search terms",
                    "A message that appears at the bottom of search results. It tells users to check what they typed to find their bank is correct."
                )
            )
        )
        if let didSelectManuallyAddYourAccount = didSelectManuallyAddYourAccount {
            verticalStackView.addArrangedSubview(
                CreateRowView(
                    image: .edit,
                    title:
                        "[\(STPLocalizedString("Manually add your account", "A title of a button that appears at the bottom of search results. If the user clicks the button, they will be able to manually enter their bank account details (a routing number and an account number)."))](https://www.use-custom-action-instead.com)",
                    customAction: didSelectManuallyAddYourAccount
                )
            )
        }
        addAndPinSubview(verticalStackView)

        // Add top/bottom separators
        let topSeparatorView = UIView()
        topSeparatorView.backgroundColor = .borderNeutral
        addSubview(topSeparatorView)
        let bottomSeparatorView = UIView()
        bottomSeparatorView.backgroundColor = .borderNeutral
        addSubview(bottomSeparatorView)
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSeparatorView.topAnchor.constraint(equalTo: topAnchor),
            topSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),

            bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
private func CreateTitleLabel() -> UIView {
    let titleLabel = UILabel()
    titleLabel.text = STPLocalizedString(
        "CAN'T FIND YOUR BANK?",
        "The title of a section that appears at the bottom of search results. It appears when a user is searching for their bank. The purpose of the section is to give users other options in case they can't find their bank."
    )
    titleLabel.font = .stripeFont(forTextStyle: .kicker)
    titleLabel.textColor = .textSecondary
    return titleLabel
}

@available(iOSApplicationExtension, unavailable)
private func CreateRowView(
    image: Image,
    title: String,
    customAction: (() -> Void)? = nil
) -> UIView {
    let shouldHighlightIcon = !title.extractLinks().links.isEmpty
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            CreateRowIconView(
                image: image,
                isHighlighted: shouldHighlightIcon
            ),
            CreateRowLabelView(
                title: title,
                customAction: customAction
            ),
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    return horizontalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateRowIconView(image: Image, isHighlighted: Bool) -> UIView {
    let iconImageView = UIImageView()
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.image = image.makeImage()
        .withTintColor(
            isHighlighted ? .textBrand : .textSecondary
        )

    let iconContainerView = UIView()
    iconContainerView.backgroundColor = isHighlighted ? .info100 : .borderNeutral
    iconContainerView.layer.cornerRadius = 4
    iconContainerView.addSubview(iconImageView)

    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 32),
        iconContainerView.heightAnchor.constraint(equalToConstant: 32),

        iconImageView.heightAnchor.constraint(equalToConstant: 16),
        iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
        iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
    ])
    return iconContainerView
}

@available(iOSApplicationExtension, unavailable)
private func CreateRowLabelView(
    title: String,
    customAction: (() -> Void)? = nil
) -> UIView {
    let titleLabel = ClickableLabel(
        font: .stripeFont(forTextStyle: .captionTightEmphasized),
        boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
        textColor: .textPrimary
    )
    if let customAction = customAction {
        titleLabel.setText(
            title,
            action: { _ in
                customAction()
            }
        )
    } else {
        titleLabel.setText(title)
    }
    return titleLabel
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct InstitutionSearchFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> InstitutionSearchFooterView {
        InstitutionSearchFooterView(didSelectManuallyAddYourAccount: {})
    }

    func updateUIView(_ uiView: InstitutionSearchFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct InstitutionSearchFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            InstitutionSearchFooterViewUIViewRepresentable()
                .frame(maxHeight: 220)
            Spacer()
        }
        .padding()
    }
}

#endif
