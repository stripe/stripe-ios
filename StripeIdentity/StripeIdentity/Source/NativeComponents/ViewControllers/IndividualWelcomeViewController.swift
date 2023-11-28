//
//  IndividualWelcomeViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/14/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class IndividualWelcomeViewController: IdentityFlowViewController {
    let flowViewModel: IdentityFlowView.ViewModel
    init(
        brandLogo: UIImage,
        welcomeContent: StripeAPI.VerificationPageStaticContentIndividualWelcomePage,
        sheetController: VerificationSheetControllerProtocol
    ) throws {

        let multilineContent = MultilineIconLabelHTMLView()

        var didOpenURLHandler: ((URL) -> Void)?

        flowViewModel = .init(
            headerViewModel: .init(
                backgroundColor: .systemBackground,
                headerType: .banner(
                    iconViewModel: .init(
                        iconType: .brand,
                        iconImage: brandLogo,
                        iconImageContentMode: .scaleToFill,
                        useLargeIcon: true
                    )
                ),
                titleText: welcomeContent.title
            ),
            contentViewModel: .init(
                view: multilineContent,
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
            ],
            buttonTopContentViewModel: .init(
                text: welcomeContent.privacyPolicy,
                style: .html(makeStyle: IdentityFlowView.privacyPolicyLineContentStyle),
                didOpenURL: { url in
                    didOpenURLHandler?(url)
                }
            )
        )

        super.init(sheetController: sheetController, analyticsScreenName: .individual_welcome)

        didOpenURLHandler = self.openInSafariViewController

        // If HTML fails to render, throw error since it's unacceptable to not
        // display consent copy
        try multilineContent.configure(
            with: .init(
                lines: welcomeContent.lines.map {
                    return ($0.icon, $0.content)
                }
            ) { [weak self] url in
                self?.presentBottomsheet(withUrl: url)
            }
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
