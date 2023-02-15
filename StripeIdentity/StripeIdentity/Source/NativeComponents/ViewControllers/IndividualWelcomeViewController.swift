//
//  IndividualWelcomeViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/14/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class IndividualWelcomeViewController: IdentityFlowViewController {
    let flowViewModel: IdentityFlowView.ViewModel
    init(
        brandLogo: UIImage,
        welcomeContent: StripeAPI.VerificationPageStaticContentIndividualWelcomePage,
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        let htmlView = HTMLViewWithIconLabels()
        flowViewModel = .init(
            headerViewModel: .init(
                backgroundColor: .systemBackground,
                headerType: .banner(
                    iconViewModel: .init(
                        iconType: .brand,
                        iconImage: brandLogo,
                        iconImageContentMode: .scaleToFill
                    )
                ),
                titleText: welcomeContent.title
            ),
            contentViewModel: .init(
                view: htmlView,
                inset: .init(top: 16, leading: 16, bottom: 8, trailing: 16)
            ),
            buttons: [
                .init(
                    text: welcomeContent.getStartedButtonText,
                    state: .enabled,
                    didTap: {
                        sheetController.transitionToIndividual()
                    }
                ),
            ]
        )

        super.init(sheetController: sheetController, analyticsScreenName: .individual_welcome)

        // If HTML fails to render, throw error since it's unacceptable to not
        // display consent copy
        try htmlView.configure(
            with: .init(
                iconText: [
                    .init(
                        image: Image.iconClock.makeImage().withTintColor(IdentityUI.iconColor),
                        text: welcomeContent.timeEstimate,
                        isTextHTML: false
                    ),
                ],
                nonIconText: [
                    .init(
                        text: welcomeContent.privacyPolicy,
                        isTextHTML: true
                    ),
                ],
                bodyHtmlString: welcomeContent.body,
                didOpenURL: { [weak self] url in
                    self?.openInSafariViewController(url: url)
                }
            )
        )

        configure(
            backButtonTitle: STPLocalizedString(
                "Welcome",
                "Back button title for returning to welcome screen of Identity verification"
            ),
            viewModel: flowViewModel
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

}
