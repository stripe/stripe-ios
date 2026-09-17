//
//  SuccessViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SuccessViewController: IdentityFlowViewController {

    private let htmlView = HTMLViewWithIconLabels()
    private let networkedIdentity: NetworkedIdentityPresenter?
    private let saveCard = UIStackView()

    init(
        successContent: StripeAPI.VerificationPageStaticContentTextPage,
        networkedIdentity context: NetworkedIdentityContext? = nil,
        sheetController: VerificationSheetControllerProtocol
    ) {
        // A reused ID is already in Link, so only the thank-you remains.
        networkedIdentity = context.flatMap { context in
            context.hasSharedDocument ? nil : NetworkedIdentityPresenter(context: context)
        }.flatMap { $0.entry.linkAvailable ? $0 : nil }
        super.init(
            sheetController: sheetController,
            analyticsScreenName: .success,
            shouldShowCancelButton: false
        )

        do {
            // In practice, this shouldn't throw an error since HTML copy will
            // be vetted. But in the event that an error occurs parsing the HTML,
            // body text will be empty but user will still see success title and
            // button.
            try htmlView.configure(
                with: .init(
                    bodyHtmlString: successContent.body,
                    didOpenURL: { [weak self] url in
                        self?.openInSafariViewController(url: url)
                    }
                )
            )
        } catch {
            sheetController.analyticsClient.logGenericError(error: error, sheetController: sheetController)
        }

        configure(
            backButtonTitle: nil,
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: .systemBackground,
                    headerType: .banner(
                        iconViewModel: .init(
                            iconType: .plain,
                            iconImage: Image.iconClock.makeImage(template: true),
                            iconImageContentMode: .center,
                            iconTintColor: .white,
                            shouldIconBackgroundMatchTintColor: true
                        )
                    ),
                    titleText: successContent.title
                ),
                contentView: networkedIdentity == nil ? htmlView : makeContentWithSaveCard(),
                buttonText: successContent.buttonText,
                didTapButton: { [weak self] in
                    self?.didTapButton()
                }
            )
        )
        networkedIdentity?.onEntryChange = { [weak self] in self?.renderSaveCard() }
        networkedIdentity?.refreshEntry()
    }

    /// Networked Identity "Button on success": offers saving this verification's ID to Link.
    private func makeContentWithSaveCard() -> UIView {
        saveCard.axis = .vertical
        saveCard.spacing = 12
        saveCard.isLayoutMarginsRelativeArrangement = true
        saveCard.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
        saveCard.backgroundColor = .secondarySystemBackground
        saveCard.layer.cornerRadius = 12
        renderSaveCard()

        let stack = UIStackView(arrangedSubviews: [htmlView, saveCard])
        stack.axis = .vertical
        stack.spacing = 24
        return stack
    }

    private func renderSaveCard() {
        guard let networkedIdentity else {
            return
        }
        saveCard.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // #TODO - Networked Identity: localize once the final mobile copy is approved.
        let title = UILabel()
        title.font = NetworkedIdentityUI.bodyEmphasizedFont
        title.numberOfLines = 0
        title.text = "Secure 1-click verification with Link"
        saveCard.addArrangedSubview(title)
        if let email = networkedIdentity.entry.accountEmail {
            let account = UILabel()
            account.font = NetworkedIdentityUI.bodyFont
            account.numberOfLines = 0
            account.text = "Link account · \(email)"
            saveCard.addArrangedSubview(account)
        }

        guard !networkedIdentity.hasSaved else {
            let saved = UILabel()
            saved.font = NetworkedIdentityUI.bodyFont
            saved.text = "Saved to Link"
            saveCard.addArrangedSubview(saved)
            return
        }
        let button = Button(configuration: .networkedIdentityPrimary(), title: "Save ID with Link")
        button.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        saveCard.addArrangedSubview(button)
    }

    @objc private func didTapSave() {
        networkedIdentity?.startSave(from: self) { [weak self] outcome in
            if outcome == .saved {
                self?.renderSaveCard()
            }
        }
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SuccessViewController {
    fileprivate func didTapButton() {
        dismiss(animated: true, completion: nil)
    }
}
