//
//  SuccessViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/16/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class SuccessViewController: IdentityFlowViewController {

    private let htmlView = HTMLViewWithIconLabels()

    init(
        successContent: VerificationPageStaticContentTextPage,
        sheetController: VerificationSheetControllerProtocol
    ) {
        super.init(sheetController: sheetController, shouldShowCancelButton: false)

        do {
            // In practice, this shouldn't throw an error since HTML copy will
            // be vetted. But in the event that an error occurs parsing the HTML,
            // body text will be empty but user will still see success title and
            // button.
            try htmlView.configure(with: .init(
                iconText: [],
                bodyHtmlString: successContent.body,
                didOpenURL: { [weak self] url in
                    self?.openInSafariViewController(url: url)
                }
            ))
        } catch {
            // TODO(mludowise|IDPROD-2816): Log an analytic
        }

        configure(
            backButtonTitle: nil,
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: IdentityUI.containerColor,
                    headerType: .banner(iconViewModel: .init(
                        iconType: .plain,
                        iconImage: Image.iconClock.makeImage(template: true),
                        iconImageContentMode: .center,
                        iconTintColor: .white,
                        shouldIconBackgroundMatchTintColor: true
                    )),
                    titleText: successContent.title
                ),
                contentView: htmlView,
                buttonText: successContent.buttonText,
                didTapButton: { [weak self] in
                    self?.didTapButton()
                }
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOSApplicationExtension, unavailable)
private extension SuccessViewController {
    func didTapButton() {
        dismiss(animated: true, completion: nil)
    }
}
