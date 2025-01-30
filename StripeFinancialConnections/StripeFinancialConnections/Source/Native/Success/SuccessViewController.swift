//
//  SuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol SuccessViewControllerDelegate: AnyObject {
    func successViewControllerDidSelectDone(_ viewController: SuccessViewController)
}

final class SuccessViewController: UIViewController {

    private let dataSource: SuccessDataSource
    weak var delegate: SuccessViewControllerDelegate?

    init(dataSource: SuccessDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        navigationItem.hidesBackButton = true

        let showSaveToLinkFailedNotice = (dataSource.saveToLinkWithStripeSucceeded == false)

        let contentView = UIView()
        view.addSubview(contentView)

        let bodyView = CreateBodyView(
            title: dataSource.customSuccessPaneCaption ?? STPLocalizedString(
                "Success",
                "The title of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments."
            ),
            subtitle: dataSource.customSuccessPaneSubCaption ?? CreateSubtitleText(
                // manual entry has "0" linked accounts count
                isLinkingOneAccount: (dataSource.linkedAccountsCount == 0 || dataSource.linkedAccountsCount == 1),
                showSaveToLinkFailedNotice: showSaveToLinkFailedNotice
            ),
            appearance: dataSource.manifest.appearance
        )
        contentView.addSubview(bodyView)

        let footerView = SuccessFooterView(
            appearance: dataSource.manifest.appearance,
            didSelectDone: { [weak self] footerView in
                guard let self = self else { return }
                // we NEVER set isLoading to `false` because
                // we will always close the Auth Flow
                footerView.setIsLoading(true)
                self.dataSource
                    .analyticsClient
                    .log(
                        eventName: "click.done",
                        pane: .success
                    )
                self.delegate?.successViewControllerDidSelectDone(self)
            }
        )
        view.addSubview(footerView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        footerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // constraint `contentView` to the top of `view` and top of `footerView`
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            contentView.bottomAnchor.constraint(equalTo: footerView.topAnchor),

            // constraint `footerView` to the bottom of `view` and bottom of `contentView`
            footerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // constraint `bodyView` to the center of `contentView`
            bodyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bodyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            // we assume `bodyView` will never be larger than `contentView`
            // available space - as is in designs today
            bodyView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .success)

        if showSaveToLinkFailedNotice {
            dataSource
                .analyticsClient
                .log(
                    eventName: "networking.save_to_link_failed_notice",
                    pane: .success
                )
        }
    }

    private var didFireFeedbackGenerator = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didFireFeedbackGenerator {
            didFireFeedbackGenerator = true
            FeedbackGeneratorAdapter.successOccurred()
        }
    }
}

private func CreateBodyView(
    title: String,
    subtitle: String?,
    appearance: FinancialConnectionsAppearance
) -> UIView {
    let titleLabel = AttributedLabel(
        font: .heading(.extraLarge),
        textColor: FinancialConnectionsAppearance.Colors.textDefault
    )
    titleLabel.setText(title)
    let labelVerticalStackView = UIStackView(
        arrangedSubviews: [titleLabel]
    )
    labelVerticalStackView.axis = .vertical
    labelVerticalStackView.spacing = 8
    labelVerticalStackView.alignment = .center

    if let subtitle = subtitle {
        let subtitleLabel = AttributedTextView(
            font: .body(.medium),
            boldFont: .body(.mediumEmphasized),
            linkFont: .body(.medium),
            textColor: FinancialConnectionsAppearance.Colors.textDefault,
            alignment: .center
        )
        subtitleLabel.setText(subtitle)
        labelVerticalStackView.addArrangedSubview(subtitleLabel)
    }

    let bodyVerticalStackView = UIStackView(
        arrangedSubviews: [
            CreateIconView(appearance: appearance),
            labelVerticalStackView,
        ]
    )
    bodyVerticalStackView.axis = .vertical
    bodyVerticalStackView.spacing = 16
    bodyVerticalStackView.alignment = .center

    // animate the whole view body to move down-to-up, and appear
    bodyVerticalStackView.alpha = 0.0
    bodyVerticalStackView.transform = CGAffineTransform(translationX: 0, y: 37)
    UIView.animate(
        withDuration: 0.35,
        delay: 0.0,
        options: [.curveEaseOut],
        animations: {
            bodyVerticalStackView.alpha = 1.0
            bodyVerticalStackView.transform = .identity
        }
    )
    return bodyVerticalStackView
}

private func CreateIconView(appearance: FinancialConnectionsAppearance) -> UIView {
    let iconContainerView = UIView()
    iconContainerView.backgroundColor = appearance.colors.primary
    let iconRadius: CGFloat = 56
    iconContainerView.layer.cornerRadius = iconRadius/2
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: iconRadius),
        iconContainerView.heightAnchor.constraint(equalToConstant: iconRadius),
    ])

    let iconImageView = UIImageView()
    iconImageView.image = Image.check.makeImage().withTintColor(appearance.colors.primaryAccent)
    iconContainerView.addSubview(iconImageView)
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconImageView.widthAnchor.constraint(equalToConstant: 20),
        iconImageView.heightAnchor.constraint(equalToConstant: 20),
        iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
        iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
    ])

    // animate the checkmark icon to bounce/appear
    iconImageView.alpha = 0
    iconImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    UIView.animate(
        withDuration: 0.35,
        delay: 0.35,
        usingSpringWithDamping: 0.45,
        initialSpringVelocity: 0.1,
        animations: {
            iconImageView.alpha = 1.0
            iconImageView.transform = .identity
        }
    )
    return iconContainerView
}

private func CreateSubtitleText(
    isLinkingOneAccount: Bool,
    showSaveToLinkFailedNotice: Bool
) -> String {
    if showSaveToLinkFailedNotice {
        if isLinkingOneAccount {
            return STPLocalizedString(
                "Your account was connected, but couldn't be saved to Link.",
                "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected, the user will be able to use the bank account for payments."
            )
        } else { // multiple bank accounts
            return STPLocalizedString(
                "Your accounts were connected, but couldn't be saved to Link.",
                "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected, the user will be able to use the bank account for payments."
            )
        }
    } else if isLinkingOneAccount {
        return STPLocalizedString(
            "Your account was connected.",
            "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank account to an application. Now that the bank account is connected (or linked), the user will be able to use the bank account for payments."
        )
    } else {  // multiple bank accounts
        return STPLocalizedString(
            "Your accounts were connected.",
            "The subtitle/description of the success screen that appears when a user is done with the process of connecting their bank accounts to an application. Now that the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments."
        )
    }
}
