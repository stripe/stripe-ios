//
//  StreamlinedConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2026-11-05.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

// The sender parameters follow the delegate convention used by the other panes.
protocol StreamlinedConsentViewControllerDelegate: AnyObject {
    // periphery:ignore:parameters viewController
    func streamlinedConsentViewController(
        _ viewController: StreamlinedConsentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    )
    // periphery:ignore:parameters viewController
    func streamlinedConsentViewController(
        _ viewController: StreamlinedConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    )
}

class StreamlinedConsentViewController: UIViewController {
    private let dataSource: StreamlinedConsentDataSource
    weak var delegate: StreamlinedConsentViewControllerDelegate?

    private lazy var footer: (footerView: UIView?, primaryButton: StripeUICore.Button?) = {
        return GenericInfoFooterViewAndPrimaryButton(
            footer: dataSource.streamlinedConsentPane.screen.footer,
            appearance: dataSource.manifest.appearance,
            didSelectPrimaryButton: didSelectAgree,
            didSelectSecondaryButton: {
                // This can't occur
            },
            didSelectURL: didSelectURLInTextFromBackend
        )
    }()

    init(dataSource: StreamlinedConsentDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        let genericInfoScreen = dataSource.streamlinedConsentPane.screen
        let logoView: UIView? = {
            guard let imageUrl = genericInfoScreen.header?.icon?.default else { return nil }
            return CreateRoundedLogoView(urlString: imageUrl)
        }()

        let contentView = PaneLayoutView.createContentView(
            iconView: logoView,
            title: genericInfoScreen.header?.title,
            subtitle: genericInfoScreen.header?.subtitle,
            headerAlignment: .center,
            horizontalPadding: 0,
            contentView: makeBodyView(body: genericInfoScreen.body)
        )
        let paneLayoutView = PaneLayoutView(contentView: contentView, footerView: footer.footerView)
        paneLayoutView.addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .streamlinedConsent)
    }

    private func makeBodyView(body: FinancialConnectionsGenericInfoScreen.Body?) -> UIView? {
        guard let entries = body?.entries, !entries.isEmpty else { return nil }

        var bullets: [FinancialConnectionsBulletPoint] = []
        for entry in entries {
            guard case .bullets(let bulletsBodyEntry) = entry else {
                // Non-bullet entries can't be rendered with the consent styling,
                // so fall back to rendering the body generically.
                return GenericInfoBodyView(
                    body: body,
                    didSelectURL: { [weak self] url in
                        self?.didSelectURLInTextFromBackend(url)
                    }
                )
            }
            for bullet in bulletsBodyEntry.bullets {
                guard let icon = bullet.icon else { continue }
                bullets.append(FinancialConnectionsBulletPoint(
                    icon: icon,
                    title: bullet.title,
                    content: bullet.content
                ))
            }
        }

        return ConsentBodyView(
            bulletItems: bullets,
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
    }

    func didSelectNavigationBarLogo() {
        guard let moreInfoNotice = dataSource.streamlinedConsentPane.moreInfoNotice else { return }
        let moreInfoViewController = GenericInfoViewController(
            genericInfoScreen: moreInfoNotice,
            appearance: dataSource.manifest.appearance,
            panePresentationStyle: .sheet,
            didSelectPrimaryButton: { genericInfoViewController in
                genericInfoViewController.dismiss(animated: true)
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
        moreInfoViewController.present(on: self)
    }

    private func didSelectAgree() {
        dataSource.analyticsClient.log(
            eventName: "click.agree",
            pane: .streamlinedConsent
        )

        footer.primaryButton?.isLoading = true
        dataSource.markConsentAcquired()
            .observe { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.streamlinedConsentViewController(self, didConsentWithManifest: manifest)
                case .failure(let error):
                    // we display no errors on failure
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "ConsentAcquiredError",
                            pane: .streamlinedConsent
                        )
                }
                self.footer.primaryButton?.isLoading = false
            }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .streamlinedConsent,
            analyticsClient: dataSource.analyticsClient,
            handleURL: { urlHost, nextPaneOrDrawerOnSecondaryCta in
                guard let urlHost, let address = StripeSchemeAddress(rawValue: urlHost) else {
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            FinancialConnectionsSheetError.unknown(
                                debugDescription: "Unknown Stripe-scheme URL detected: \(urlHost ?? "nil")."
                            ),
                            errorName: "ConsentStripeURLError",
                            pane: .streamlinedConsent
                        )
                    return
                }

                switch address {
                case .manualEntry:
                    delegate?.streamlinedConsentViewController(
                        self,
                        didRequestNextPane: .manualEntry,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                case .dataAccessNotice:
                    guard let dataAccessNotice = dataSource.dataAccessNotice else {
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                FinancialConnectionsSheetError.unknown(
                                    debugDescription: "Data access notice requested, but none was provided."
                                ),
                                errorName: "ConsentStripeURLError",
                                pane: .streamlinedConsent
                            )
                        return
                    }
                    let dataAccessNoticeViewController = DataAccessNoticeViewController(
                        dataAccessNotice: dataAccessNotice,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    dataAccessNoticeViewController.present(on: self)
                case .legalDatailsNotice:
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: dataSource.streamlinedConsentPane.legalDetailsNotice,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                case .linkAccountPicker:
                    delegate?.streamlinedConsentViewController(
                        self,
                        didRequestNextPane: .linkAccountPicker,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                case .linkLogin:
                    delegate?.streamlinedConsentViewController(
                        self,
                        didRequestNextPane: .networkingLinkLoginWarmup,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                }
            }
        )
    }
}
