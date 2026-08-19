//
//  DocumentWarmupViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 11/6/23.
//

import Foundation
import PassKit
import UIKit
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
                VerifyWithWalletLogger.log("continue-with-camera tapped (wallet unavailable), transitioning to document capture")
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
            VerifyWithWalletLogger.log("viewDidLoad: skipping wallet availability check, iOS <16")
            return
        }

        Task { @MainActor in
            let isVerifyDocumentViaWalletAvailable = await verifyViaWalletManager.isVerifyDocumentViaWalletAvailable()
            VerifyWithWalletLogger.log("isVerifyDocumentViaWalletAvailable=\(isVerifyDocumentViaWalletAvailable)")
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
                        VerifyWithWalletLogger.log("continue-with-camera tapped, transitioning to document capture")
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

                        VerifyWithWalletLogger.log("button tapped")
                        updateVerifyViaWalletFlowViewModel(walletButtonState: .loading)
                        Task { @MainActor in
                            defer {
                                self.updateVerifyViaWalletFlowViewModel(walletButtonState: .enabled)
                            }

                            do {
                                let outcome = try await self.verifyViaWalletManager.requestDocument()
                                VerifyWithWalletLogger.log("requestDocument returned outcome=\(outcome)")
                                switch outcome {
                                case .credentialReturned(let encryptedResponse):
                                    VerifyWithWalletLogger.log("credential returned, presenting wallet payload before transitioning to success screen")
                                    self.presentWalletPayload(encryptedResponse: encryptedResponse) {
                                        self.sheetController?.transitionToSuccess()
                                    }
                                case .userDeclined, .noDocument:
                                    VerifyWithWalletLogger.log("falling back to camera flow, outcome=\(outcome)")
                                    self.sheetController?.transitionToDocumentCapture()
                                }
                            } catch {
                                VerifyWithWalletLogger.logError("requestDocument failed: \(error)")
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

    // TODO(for demo): remove once the wallet payload doesn't need manual inspection
    @available(iOS 16.0, *)
    private func presentWalletPayload(encryptedResponse: String, completion: @escaping () -> Void) {
        let payloadData = try? JSONSerialization.data(
            withJSONObject: [
                "session_id": VerifyDocumentViaWalletManager.lastWalletIdentitySessionId ?? "nil",
                "encrypted_data": encryptedResponse,
            ],
            options: [.prettyPrinted, .sortedKeys]
        )
        let payload = payloadData.flatMap { String(bytes: $0, encoding: .utf8) } ?? encryptedResponse

        let textView = UITextView()
        textView.text = payload
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false

        let viewController = UIViewController()
        viewController.title = "Wallet payload"
        viewController.view.backgroundColor = .systemBackground
        viewController.view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak viewController] _ in
                viewController?.dismiss(animated: true, completion: completion)
            }
        )
        viewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Copy",
            primaryAction: UIAction { _ in UIPasteboard.general.string = payload }
        )
        present(UINavigationController(rootViewController: viewController), animated: true)
    }
}
