//
//  DocumentWarmupViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 11/6/23.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

final class DocumentWarmupViewController: IdentityFlowViewController {
    var flowViewModel: IdentityFlowView.ViewModel
    private let staticContent: StripeAPI.VerificationPageStaticContentDocumentSelectPage
    private let verifyViaWalletManager: VerifyDocumentViaWalletManagerProtocol

    init(
        sheetController: VerificationSheetControllerProtocol,
        staticContent: StripeAPI.VerificationPageStaticContentDocumentSelectPage,
        verifyViaWalletManager: any VerifyDocumentViaWalletManagerProtocol
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
        self.staticContent = staticContent
        self.verifyViaWalletManager = verifyViaWalletManager
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

    override func viewDidLoad() {
        super.viewDidLoad()

        guard #available(iOS 16.0, *) else {
            return
        }

        Task { @MainActor in
            let isVerifyDocumentViaWalletAvailable = await verifyViaWalletManager.isVerifyDocumentViaWalletAvailable()
            if isVerifyDocumentViaWalletAvailable {
                updateVerifyViaWalletFlowViewModel(walletButtonState: .enabled)
            }
        }
    }

    @available(iOS 16.0, *)
    private func updateVerifyViaWalletFlowViewModel(walletButtonState: IdentityFlowView.ViewModel.Button.State) {
        flowViewModel = .init(
            headerViewModel: nil,
            contentViewModel: .init(view: DocumentWarmupView(staticContent: staticContent), inset: nil),
            buttons: [
                .init(
                    text: String.Localized.continueWithCamera,
                    state: .enabled,
                    isPrimary: true,
                    didTap: { [weak self] in
                        self?.sheetController?.transitionToDocumentCapture()
                    }
                ),
                .init(
                    makeControl: {
                        let button = PKIdentityButton(label: .verifyIdentity, style: .black)
                        let standardButtonConfiguration = IdentityFlowView.Style.buttonConfiguration(isPrimary: true)
                        button.cornerRadius = standardButtonConfiguration.cornerRadius
                        button.heightAnchor.constraint(
                            equalToConstant: Button(configuration: standardButtonConfiguration).intrinsicContentSize.height
                        ).isActive = true
                        return button
                    },
                    state: walletButtonState,
                    didTap: { [weak self] in
                        guard let self else {
                            return
                        }

                        updateVerifyViaWalletFlowViewModel(walletButtonState: .loading)
                        Task { @MainActor in
                            defer {
                                self.updateVerifyViaWalletFlowViewModel(walletButtonState: .enabled)
                            }

                            do {
                                let status = try await self.verifyViaWalletManager.requestDocument()
                                if status == .validated {
                                    self.sheetController?.submitVerificationPageAndTransition(
                                        from: self.analyticsScreenName
                                    ) {}
                                }
                            } catch {
                                debugPrint("Verify via Wallet failed: \(error)")
                            }
                        }
                    }
                ),
            ],
            buttonTopContentViewModel: .init(
                text: String.Localized.documentFrontWarmupBody,
                style: .plainText(
                    font: IdentityUI.instructionsFont,
                    textColor: IdentityUI.textColor
                ),
                didOpenURL: { _ in }
            )
        )

        configure(
            backButtonTitle: nil,
            viewModel: flowViewModel
        )
    }
}
