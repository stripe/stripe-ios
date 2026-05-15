//
//  NetworkingLinkLoginWarmupViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

typealias NetworkingLinkLoginWarmupFooterView = (footerView: UIView?, primaryButton: StripeUICore.Button?, secondaryButton: StripeUICore.Button?)

protocol NetworkingLinkLoginWarmupViewControllerDelegate: AnyObject {
    func networkingLinkLoginWarmupViewControllerDidSelectContinue(
        _ viewController: NetworkingLinkLoginWarmupViewController
    )
    func networkingLinkLoginWarmupViewControllerDidFindConsumerSession(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        consumerSession: ConsumerSessionData,
        consumerPublishableKey: String,
        linkBrand: LinkBrand?
    )
    func networkingLinkLoginWarmupViewControllerDidSelectCancel(
        _ viewController: NetworkingLinkLoginWarmupViewController
    )
    func networkingLinkLoginWarmupViewController(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        didSelectSkipWithManifest manifest: FinancialConnectionsSessionManifest
    )
    func networkingLinkLoginWarmupViewController(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        didReceiveTerminalError error: Error
    )
    func networkingLinkLoginWarmupViewControllerDidFailAttestationVerdict(
        _ viewController: NetworkingLinkLoginWarmupViewController,
        prefillDetails: WebPrefillDetails
    )
}

final class NetworkingLinkLoginWarmupViewController: SheetViewController {

    private let dataSource: NetworkingLinkLoginWarmupDataSource
    weak var delegate: NetworkingLinkLoginWarmupViewControllerDelegate?
    private var linkBrand: LinkBrand {
        dataSource.linkBrand
    }

    private lazy var warmupFooterView: NetworkingLinkLoginWarmupFooterView = {
        let secondaryButtonTitle: String
        if dataSource.manifest.isProductInstantDebits {
            secondaryButtonTitle = String.Localized.cancel
        } else {
            secondaryButtonTitle = STPLocalizedString(
                "Not now",
                "A button title. This button, when pressed, will skip logging in the user with their e-mail to Link (one-click checkout provider)."
            )
        }
        return PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: String.Localized.continue_with_link(brand: linkBrand),
                accessibilityIdentifier: "link_continue_button",
                action: { [weak self] in
                    self?.didSelectContinue()
                }
            ),
            secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: secondaryButtonTitle,
                action: { [weak self] in
                    self?.didSelectSkip()
                }
            ),
            appearance: dataSource.manifest.appearance
        )
    }()

    init(
        dataSource: NetworkingLinkLoginWarmupDataSource,
        panePresentationStyle: PanePresentationStyle
    ) {
        self.dataSource = dataSource
        super.init(panePresentationStyle: panePresentationStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: RoundedIconView(
                    image: .image(.person),
                    style: .circle,
                    appearance: dataSource.manifest.appearance
                ),
                title: String.Localized.continue_with_link(brand: linkBrand),
                subtitle: String.Localized.use_information_you_previously_saved_with_your_brand_account(brand: linkBrand),
                contentView: NetworkingLinkLoginWarmupBodyView(
                    // `email` should always be non-null, and since the email is only used as a visual, it's not worth to throw an error if it is null
                    email: dataSource.email ?? "you"
                )
            ),
            footerView: warmupFooterView.footerView
        )
    }

    private func didSelectContinue() {
        dataSource.analyticsClient.log(
            eventName: "click.continue",
            pane: .networkingLinkLoginWarmup
        )

        if dataSource.hasConsumerSession {
            // We already have a consumer session, so let's us this one directly
            delegate?.networkingLinkLoginWarmupViewControllerDidSelectContinue(self)
        } else {
            // Otherwise, look it up so that we have it for the next pane
            lookupConsumerSessionAndContinue()
        }
    }

    private func lookupConsumerSessionAndContinue() {
        warmupFooterView.primaryButton?.isLoading = true

        dataSource
            .lookupConsumerSession()
            .observe { [weak self] result in
                guard let self else { return }

                warmupFooterView.primaryButton?.isLoading = false

                let attestationError = self.dataSource.completeAssertionIfNeeded(
                    possibleError: result.error,
                    api: .consumerSessionLookup
                )

                if attestationError != nil {
                    let prefillDetails = WebPrefillDetails(email: self.dataSource.email)
                    self.delegate?.networkingLinkLoginWarmupViewControllerDidFailAttestationVerdict(self, prefillDetails: prefillDetails)
                    return
                }

                switch result {
                case .success(let response):
                    PresentationManager.shared.updateLinkBrandFromBackend(response.linkBrand)
                    if let consumerSession = response.consumerSession, let publishableKey = response.publishableKey {
                        self.delegate?.networkingLinkLoginWarmupViewControllerDidFindConsumerSession(
                            self,
                            consumerSession: consumerSession,
                            consumerPublishableKey: publishableKey,
                            linkBrand: response.linkBrand
                        )
                        self.delegate?.networkingLinkLoginWarmupViewControllerDidSelectContinue(self)
                    } else {
                        let error = FinancialConnectionsSheetError.unknown(
                            debugDescription: "Unexpected consumer lookup response without consumer session or publishable key"
                        )
                        dataSource.analyticsClient.logUnexpectedError(
                            error,
                            errorName: "UnexpectedLookupResponseError",
                            pane: .networkingLinkLoginWarmup
                        )
                        self.delegate?.networkingLinkLoginWarmupViewController(self, didReceiveTerminalError: error)
                    }
                case .failure(let error):
                    self.delegate?.networkingLinkLoginWarmupViewController(self, didReceiveTerminalError: error)
                }
            }
    }

    private func didSelectSkip() {
        if dataSource.manifest.isProductInstantDebits {
            guard let delegate else {
                dataSource
                    .analyticsClient
                    .logUnexpectedError(
                        FinancialConnectionsSheetError.unknown(
                            debugDescription: "Unexpected nil delegate in the NetworkLinkLoginWarmup pane when selecting Cancel."
                        ),
                        errorName: "InstantDebitsCancelError",
                        pane: .networkingLinkLoginWarmup
                    )
                return
            }
            delegate.networkingLinkLoginWarmupViewControllerDidSelectCancel(self)
        } else {
            dataSource.analyticsClient.log(
                eventName: "click.skip_sign_in",
                pane: .networkingLinkLoginWarmup
            )
            dataSource.disableNetworking()
                .observe { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let manifest):
                        self.delegate?.networkingLinkLoginWarmupViewController(
                            self,
                            didSelectSkipWithManifest: manifest
                        )
                    case .failure(let error):
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "DisableNetworkingError",
                                pane: .networkingLinkLoginWarmup
                            )
                        self.delegate?.networkingLinkLoginWarmupViewController(self, didReceiveTerminalError: error)
                    }
                }
        }
    }
}
