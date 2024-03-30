//
//  DocumentWarmupViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 11/6/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class DocumentWarmupViewController: IdentityFlowViewController {
    let flowViewModel: IdentityFlowView.ViewModel

    init(
        sheetController: VerificationSheetControllerProtocol,
        staticContent: StripeAPI.VerificationPageStaticContentDocumentSelectPage
    ) throws {
        flowViewModel = .init(
            headerViewModel: nil,
            contentView: DocumentWarmupView(staticContent: staticContent),
            buttonText: String.Localized.imReady,
            state: .enabled,
            buttonTopContentViewModel: .init(
                text: String.Localized.documentFrontWarmupBody,
                style: .plainText(
                    font: IdentityUI.instructionsFont,
                    textColor: IdentityUI.textColor
                ),
                didOpenURL: { _ in }
            ),
            didTapButton: {
                sheetController.transitionToDocumentCapture()
            }
        )
        super.init(sheetController: sheetController, analyticsScreenName: .documentWarmup)
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
