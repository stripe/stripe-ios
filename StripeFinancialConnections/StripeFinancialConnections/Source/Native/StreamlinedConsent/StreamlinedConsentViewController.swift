//
//  StreamlinedConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 2025-02-05.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol StreamlinedConsentViewControllerDelegate: AnyObject {
    func streamlinedConsentViewController(
        _ viewController: StreamlinedConsentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    )
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
            footer: dataSource.streamlinedConsentContent.screen.footer,
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

        let genericInfoScreen = dataSource.streamlinedConsentContent.screen
        let logoView: UIView? = {
            guard let imageUrl = genericInfoScreen.header?.icon?.default else { return nil }
            return CreateRoundedLogoView(urlString: imageUrl)
        }()

        let bodyView: ConsentBodyView? = {
            guard let entries = genericInfoScreen.body?.entries else { return nil }

            var bullets: [FinancialConnectionsBulletPoint] = []
            for entry in entries {
                guard case .bullets(let bulletsBodyEntry) = entry else { continue }
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
        }()

        let contentView = PaneLayoutView.createContentView(
            iconView: logoView,
            title: genericInfoScreen.header?.title,
            subtitle: genericInfoScreen.header?.subtitle,
            headerAlignment: .center,
            horizontalPadding: 0,
            contentView: bodyView
        )
        let paneLayoutView = PaneLayoutView(contentView: contentView, footerView: footer.footerView)
        paneLayoutView.addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .streamlinedConsent)
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
                footer.primaryButton?.isLoading = false
            }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .streamlinedConsent,
            analyticsClient: dataSource.analyticsClient,
            handleURL: { urlHost, _ in
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
                case .legalDatailsNotice:
                    let legalDetailsNoticeModel = dataSource.streamlinedConsentContent.legalDetailsNotice
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNoticeModel,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                case .manualEntry:
                    self.delegate?.streamlinedConsentViewController(
                        self,
                        didRequestNextPane: .manualEntry,
                        nextPaneOrDrawerOnSecondaryCta: nil
                    )
                case .dataAccessNotice:
                    if let dataAccessNotice = dataSource.streamlinedConsentContent.dataAccessNotice {
                        let dataAccessNoticeViewController = DataAccessNoticeViewController(
                            dataAccessNotice: dataAccessNotice,
                            appearance: dataSource.manifest.appearance,
                            didSelectUrl: { [weak self] url in
                                self?.didSelectURLInTextFromBackend(url)
                            }
                        )
                        dataAccessNoticeViewController.present(on: self)
                    }
                case .linkAccountPicker, .linkLogin:
                    assertionFailure("Streamlined Consent pane text in URL does not support \(address.rawValue)")
                }
            }
        )
    }
}
