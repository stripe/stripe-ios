//
//  ConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/14/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol ConsentViewControllerDelegate: AnyObject {
    func consentViewControllerDidSelectManuallyVerify(_ viewController: ConsentViewController)
    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    )
}

class ConsentViewController: UIViewController {

    private let dataSource: ConsentDataSource
    weak var delegate: ConsentViewControllerDelegate?

    private lazy var titleLabel: AttributedTextView = {
        let titleLabel = AttributedTextView(
            font: .heading(.extraLarge),
            boldFont: .heading(.extraLarge),
            linkFont: .heading(.extraLarge),
            textColor: .textDefault,
            alignCenter: true
        )
        titleLabel.setText(
            dataSource.consent.title,
            action: { [weak self] url in
                // there are no known cases where we add a link to the title
                // but we add this handling regardless in case this changes
                // in the future
                self?.didSelectURLInTextFromBackend(url)
            }
        )
        return titleLabel
    }()
    private lazy var footerView: ConsentFooterView = {
        return ConsentFooterView(
            aboveCtaText: dataSource.consent.aboveCta,
            ctaText: dataSource.consent.cta,
            belowCtaText: dataSource.consent.belowCta,
            didSelectAgree: { [weak self] in
                self?.didSelectAgree()
            },
            didSelectURL: { [weak self] url in
                self?.didSelectURLInTextFromBackend(url)
            }
        )
    }()
    private var consentLogoView: ConsentLogoView?

    init(dataSource: ConsentDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        let paneLayoutView = PaneLayoutView(
            contentView: {
                let verticalStackView = HitTestStackView()
                verticalStackView.axis = .vertical
                verticalStackView.spacing = 24
                verticalStackView.isLayoutMarginsRelativeArrangement = true
                verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    top: 24,
                    leading: 24,
                    bottom: 8,
                    trailing: 24
                )
                if let merchantLogo = dataSource.merchantLogo {
                    let consentLogoView = ConsentLogoView(merchantLogo: merchantLogo)
                    self.consentLogoView = consentLogoView
                    verticalStackView.addArrangedSubview(consentLogoView)
                }
                verticalStackView.addArrangedSubview(titleLabel)
                verticalStackView.addArrangedSubview(
                    ConsentBodyView(
                        bulletItems: dataSource.consent.body.bullets,
                        didSelectURL: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                )
                return verticalStackView
            }(),
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .consent)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // this fixes an issue where presenting a UIViewController
        // on top of ConsentViewController would stop the dot animation
        consentLogoView?.animateDots()
    }

    private func didSelectAgree() {
        dataSource.analyticsClient.log(
            eventName: "click.agree",
            pane: .consent
        )

        footerView.setIsLoading(true)
        dataSource.markConsentAcquired()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.consentViewController(self, didConsentWithManifest: manifest)
                case .failure(let error):
                    // we display no errors on failure
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "ConsentAcquiredError",
                            pane: .consent
                        )
                }
                self.footerView.setIsLoading(false)
            }
    }

    private func didSelectURLInTextFromBackend(_ url: URL) {
        AuthFlowHelpers.handleURLInTextFromBackend(
            url: url,
            pane: .consent,
            analyticsClient: dataSource.analyticsClient,
            handleStripeScheme: { urlHost in
                if urlHost == "manual-entry" {
                    delegate?.consentViewControllerDidSelectManuallyVerify(self)
                } else if urlHost == "data-access-notice" {
                    if let dataAccessNotice = dataSource.consent.dataAccessNotice {
                        let dataAccessNoticeViewController = DataAccessNoticeViewController(
                            dataAccessNotice: dataAccessNotice,
                            didSelectUrl: { [weak self] url in
                                self?.didSelectURLInTextFromBackend(url)
                            }
                        )
                        dataAccessNoticeViewController.present(on: self)
                    }
                } else if urlHost == "legal-details-notice" {
                    let legalDetailsNoticeModel = dataSource.consent.legalDetailsNotice
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNoticeModel,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                }
            }
        )
    }
}
