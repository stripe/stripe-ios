//
//  CountryNotListedViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/4/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class CountryNotListedViewController: IdentityFlowViewController {

    init(
        missingType: IndividualFormElement.MissingType,
        countryNotListedContent: StripeAPI.VerificationPageStaticContentCountryNotListedPage,
        sheetController: VerificationSheetControllerProtocol
    ) {
        super.init(
            sheetController: sheetController,
            analyticsScreenName: .countryNotListed
        )

        let bodyHtml = HTMLViewWithIconLabels()

        let otherCountryButtonTitle: String
        if missingType == .address {
            otherCountryButtonTitle = countryNotListedContent.addressFromOtherCountryTextButtonText
        } else {
            otherCountryButtonTitle = countryNotListedContent.idFromOtherCountryTextButtonText
        }

        let otherCountryButton: Button = .init(
            configuration: .identityOtherCountry,
            title: otherCountryButtonTitle
        )
        let stack = UIStackView(
            arrangedSubviews: [bodyHtml, otherCountryButton]
        )
        stack.axis = .vertical
        stack.alignment = .leading

        otherCountryButton.addTarget(self, action: #selector(didTapOtherCountry(button:)), for: .touchUpInside)

        do {
            // In practice, this shouldn't throw an error since HTML copy will
            // be vetted. But in the event that an error occurs parsing the HTML,
            // body text will be empty but user will still see success title and
            // button.
            try bodyHtml.configure(
                with: .init(
                    bodyHtmlString: countryNotListedContent.body,
                    didOpenURL: { [weak self] url in
                        self?.openInSafariViewController(url: url)
                    }
                )
            )
        } catch {
            sheetController.analyticsClient.logGenericError(error: error)
        }

        configure(
            backButtonTitle: nil,
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: .systemBackground,
                    headerType: .banner(
                        iconViewModel: .init(
                            iconType: .plain,
                            iconImage: Image.iconWarning.makeImage(template: true),
                            iconImageContentMode: .center,
                            iconTintColor: .white,
                            shouldIconBackgroundMatchTintColor: true
                        )
                    ),
                    titleText: countryNotListedContent.title
                ),
                contentView: stack,
                buttonText: countryNotListedContent.cancelButtonText,
                didTapButton: { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                }
            )
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func didTapOtherCountry(button: Button) {
        // go back to previous screen
        navigationController?.popViewController(animated: true)
    }
}

fileprivate extension Button.Configuration {
    static var identityOtherCountry: Button.Configuration {
        var identityCountryNotListed = Button.Configuration.plain()
        identityCountryNotListed.font = .boldSystemFont(ofSize: 15)
        return identityCountryNotListed
    }
}
