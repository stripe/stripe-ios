//
//  SelfieWelcomeViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/15/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SelfieWarmupViewController: IdentityFlowViewController {
    let flowViewModel: IdentityFlowView.ViewModel

    init(
        sheetController: VerificationSheetControllerProtocol,
        trainingConsentText: String? = nil
    ) throws {
        var didOpenURLHandler: ((URL) -> Void)?
        let warmupView = SelfieWarmupView()
        let showsTrainingConsent = trainingConsentText?.isEmpty == false

        let buttons: [IdentityFlowView.ViewModel.Button] = {
            if showsTrainingConsent {
                return [
                    .init(
                        text: String.Localized.allow,
                        state: .enabled,
                        didTap: {
                            sheetController.transitionToSelfieCapture(
                                trainingConsent: true
                            )
                        }
                    ),
                    .init(
                        text: String.Localized.decline,
                        state: .enabled,
                        isPrimary: false,
                        didTap: {
                            sheetController.transitionToSelfieCapture(
                                trainingConsent: false
                            )
                        }
                    ),
                ]
            }

            return [
                .continueButton {
                    sheetController.transitionToSelfieCapture(
                        trainingConsent: nil
                    )
                },
            ]
        }()
        let buttonTopContentViewModel: HTMLTextView.ViewModel? = {
            guard let trainingConsentText, !trainingConsentText.isEmpty else {
                return nil
            }

            return .init(
                text: SelfieWarmupViewController.trainingConsentHTMLText(trainingConsentText),
                style: .html(makeStyle: SelfieWarmupViewController.trainingConsentHTMLStyle),
                didOpenURL: { url in
                    didOpenURLHandler?(url)
                }
            )
        }()
        flowViewModel = .init(
            headerViewModel: nil,
            contentViewModel: .init(
                view: warmupView,
                inset: nil
            ),
            buttons: buttons,
            buttonTopContentViewModel: buttonTopContentViewModel
        )
        super.init(sheetController: sheetController, analyticsScreenName: .selfieWarmup)
        didOpenURLHandler = self.openInSafariViewController
        configure(
            backButtonTitle: nil,
            viewModel: flowViewModel
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

}

private extension SelfieWarmupViewController {
    static func trainingConsentHTMLText(_ trainingConsentText: String) -> String {
        return """
            <b>\(String.Localized.selfieWarmupTrainingConsentTitle)</b><br/><br/>\(trainingConsentText)
            """
    }

    static func trainingConsentHTMLStyle() -> HTMLStyle {
        let contentColor = IdentityUI.htmlLineTextColor
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: .caption1),
            bodyColor: contentColor,
            isLinkUnderlined: true,
            shouldCenterText: true,
            linkColor: contentColor
        )
    }
}
