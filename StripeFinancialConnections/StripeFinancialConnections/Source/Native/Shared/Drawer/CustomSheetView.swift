//
//  CustomSheetView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/19/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A reusable view that allows developers to quickly
/// render a sheet with a header, content, and buttons.
@available(iOSApplicationExtension, unavailable)
final class CustomSheetView: UIView {

    enum IconType {
        case view(UIView)
        case systemIcon(Image)
    }

    struct ButtonConfiguration {
        let title: String
        let action: () -> Void
    }

    private let primaryButtonAction: (() -> Void)?
    private let secondaryButtonAction: (() -> Void)?

    init(
        iconType: IconType,
        title: String,
        subtitle: String,
        contentView: UIView?,
        // the primary button is the top-most button
        primaryButtonConfiguration: ButtonConfiguration? = nil,
        secondaryButtonConfiguration: ButtonConfiguration? = nil
    ) {
        self.primaryButtonAction = primaryButtonConfiguration?.action
        self.secondaryButtonAction = secondaryButtonConfiguration?.action
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        let layoutView = CustomSheetLayoutView(
            contentView: {
                let contentStackView = UIStackView(
                    arrangedSubviews: [
                        CreateHeaderView(
                            icon: iconType,
                            title: title,
                            subtitle: subtitle,
                            bottomPadding: (contentView != nil) ? 24 : 8
                        ),
                    ]
                )
                contentStackView.spacing = 0 // set default spacing for all cases, then use custom spacing for each part
                contentStackView.axis = .vertical

                if let contentView = contentView {
                    contentStackView.addArrangedSubview(contentView)
                }
                return contentStackView
            }(),
            footerView: {
                if primaryButtonConfiguration != nil || secondaryButtonConfiguration != nil {
                    return CreateFooterView(
                        primaryButtonConfiguration: primaryButtonConfiguration,
                        secondaryButtonConfiguration: secondaryButtonConfiguration,
                        view: self
                    )
                } else {
                    return nil
                }
            }()
        )
        layoutView.addTo(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func didSelectPrimaryButton() {
        primaryButtonAction?()
    }

    @objc fileprivate func didSelectSecondaryButton() {
        secondaryButtonAction?()
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateHeaderView(
    icon: CustomSheetView.IconType?,
    title: String,
    subtitle: String?,
    bottomPadding: CGFloat
) -> UIView {
    let headerStackView = HitTestStackView()
    headerStackView.axis = .vertical
    headerStackView.spacing = 16
    headerStackView.alignment = .leading
    if let icon = icon {
        headerStackView.addArrangedSubview(
            CreateIconView(iconType: icon)
        )
    }
    headerStackView.addArrangedSubview(
        CreateTitleAndSubtitleView(
            title: title,
            subtitle: subtitle
        )
    )

    let paddingStackView = HitTestStackView(
        arrangedSubviews: [
            headerStackView
        ]
    )
    paddingStackView.isLayoutMarginsRelativeArrangement = true
    paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 0, // the sheet handle adds some padding
        leading: 24,
        bottom: bottomPadding,
        trailing: 24
    )
    return paddingStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateIconView(iconType: CustomSheetView.IconType) -> UIView {
    switch iconType {
    case .view(let iconView):
        return iconView
    case .systemIcon(let image):
        return RoundedIconView(image: image, style: .circle)
//        return SystemIconView(image: image)
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateTitleAndSubtitleView(title: String, subtitle: String?) -> UIView {
    let labelStackView = HitTestStackView()
    labelStackView.axis = .vertical
    labelStackView.spacing = 16

    let titleLabel = AttributedTextView(
        font: .heading(.large),
        boldFont: .heading(.large),
        linkFont: .heading(.large),
        textColor: .textPrimary
    )
    titleLabel.setText(title)
    labelStackView.addArrangedSubview(titleLabel)

    if let subtitle = subtitle {
        let subtitleLabel = AttributedTextView(
            font: .body(.medium),
            boldFont: .body(.mediumEmphasized),
            linkFont: .body(.mediumEmphasized),
            textColor: .textPrimary
        )
        subtitleLabel.setText(subtitle)
        labelStackView.addArrangedSubview(subtitleLabel)
    }
    return labelStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateFooterView(
    primaryButtonConfiguration: CustomSheetView.ButtonConfiguration?,
    secondaryButtonConfiguration: CustomSheetView.ButtonConfiguration?,
    view: CustomSheetView
) -> UIView? {
    guard
        primaryButtonConfiguration != nil || secondaryButtonConfiguration != nil
    else {
        return nil  // display no footer
    }
    let footerStackView = UIStackView()
    footerStackView.axis = .vertical
    footerStackView.spacing = 8
    if let primaryButtonConfiguration = primaryButtonConfiguration {
        let primaryButton = Button(configuration: FinancialConnectionsPrimaryButtonConfiguration())
        primaryButton.title = primaryButtonConfiguration.title
        primaryButton.addTarget(
            view,
            action: #selector(CustomSheetView.didSelectPrimaryButton),
            for: .touchUpInside
        )
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        footerStackView.addArrangedSubview(primaryButton)
    }
    if let secondaryButtonConfiguration = secondaryButtonConfiguration {
        let secondaryButton = Button(configuration: .secondary())
        secondaryButton.title = secondaryButtonConfiguration.title
        secondaryButton.addTarget(
            view,
            action: #selector(CustomSheetView.didSelectSecondaryButton),
            for: .touchUpInside
        )
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        footerStackView.addArrangedSubview(secondaryButton)
    }

    let paddingStackView = HitTestStackView(
        arrangedSubviews: [
            footerStackView
        ]
    )
    paddingStackView.isLayoutMarginsRelativeArrangement = true
    paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16,
        leading: 24,
        bottom: 24,
        trailing: 24
    )
    return paddingStackView
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct CustomSheetViewUIViewRepresentable: UIViewRepresentable {

    let primaryButtonConfiguration: CustomSheetView.ButtonConfiguration?
    let secondaryButtonConfiguration: CustomSheetView.ButtonConfiguration?

    func makeUIView(context: Context) -> CustomSheetView {
        CustomSheetView(
            iconType: .systemIcon(.check),
            title: "Sure you want to exit?",
            subtitle: "You haven’t finished linking you bank account and all progress will be lost.",
            contentView: nil,
            primaryButtonConfiguration: primaryButtonConfiguration,
            secondaryButtonConfiguration: secondaryButtonConfiguration
        )
    }

    func updateUIView(_ uiView: CustomSheetView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct CustomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CustomSheetViewUIViewRepresentable(
                primaryButtonConfiguration: CustomSheetView.ButtonConfiguration(
                    title: "Yes, exit",
                    action: {}
                ),
                secondaryButtonConfiguration: CustomSheetView.ButtonConfiguration(
                    title: "No, continue",
                    action: {}
                )
            )
            .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.3))

        VStack {
            CustomSheetViewUIViewRepresentable(
                primaryButtonConfiguration: nil,
                secondaryButtonConfiguration: nil
            )
            .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#endif
