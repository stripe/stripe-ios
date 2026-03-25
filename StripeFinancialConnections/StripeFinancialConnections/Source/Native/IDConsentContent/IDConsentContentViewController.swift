//
//  IDConsentContentViewController.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-03-10.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol IDConsentContentViewControllerDelegate: AnyObject {
    func idConsentContentViewController(
        _ viewController: IDConsentContentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    )
    func idConsentContentViewController(
        _ viewController: IDConsentContentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    )
}

class IDConsentContentViewController: UIViewController {
    private let dataSource: IDConsentContentDataSource
    weak var delegate: IDConsentContentViewControllerDelegate?

    private lazy var footer: (footerView: UIView?, primaryButton: StripeUICore.Button?) = {
        return GenericInfoFooterViewAndPrimaryButton(
            footer: dataSource.idConsentContent.screen.footer,
            appearance: dataSource.manifest.appearance,
            didSelectPrimaryButton: didSelectAgree,
            didSelectSecondaryButton: {
                // This can't occur
            },
            didSelectURL: didSelectURLInTextFromBackend
        )
    }()

    init(dataSource: IDConsentContentDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

        let genericInfoScreen = dataSource.idConsentContent.screen
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

        dataSource.analyticsClient.logPaneLoaded(pane: .idConsentContent)
    }

    private func didSelectAgree() {
        dataSource.analyticsClient.log(
            eventName: "click.agree",
            pane: .idConsentContent
        )

        footer.primaryButton?.isLoading = true
        dataSource.markConsentAcquired()
            .observe { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.idConsentContentViewController(self, didConsentWithManifest: manifest)
                case .failure(let error):
                    // we display no errors on failure
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "ConsentAcquiredError",
                            pane: .idConsentContent
                        )
                }
                footer.primaryButton?.isLoading = false
            }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .idConsentContent,
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
                            pane: .idConsentContent
                        )
                    return
                }

                switch address {
                case .legalDatailsNotice:
                    let legalDetailsNoticeModel = dataSource.idConsentContent.legalDetailsNotice
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNoticeModel,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                case .manualEntry, .dataAccessNotice, .linkAccountPicker, .linkLogin:
                    assertionFailure("ID Consent Content pane text in URL does not support \(address.rawValue)")
                }
            }
        )
    }
}
