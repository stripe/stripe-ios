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
            font: .heading(.large),
            boldFont: .heading(.large),
            linkFont: .heading(.large),
            textColor: .textPrimary,
            alignCenter: dataSource.merchantLogo != nil
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

        let paneLayoutView = PaneWithCustomHeaderLayoutView(
            headerView: {
                if let merchantLogo = dataSource.merchantLogo {
                    let stackView = UIStackView(
                        arrangedSubviews: [
                            ConsentLogoView(merchantLogo: merchantLogo),
                            titleLabel,
                        ]
                    )
                    stackView.axis = .vertical
                    stackView.spacing = 24
                    stackView.alignment = .center
                    return stackView
                } else {
                    return titleLabel
                }
            }(),
            headerTopMargin: 16,
            contentView: ConsentBodyView(
                bulletItems: dataSource.consent.body.bullets,
                didSelectURL: { [weak self] url in
                    self?.didSelectURLInTextFromBackend(url)
                }
            ),
            headerAndContentSpacing: 24.0,
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .consent)
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
                    let dataAccessNoticeModel = dataSource.consent.dataAccessNotice
                    let consentBottomSheetModel = ConsentBottomSheetModel(
                        title: dataAccessNoticeModel.title,
                        subtitle: dataAccessNoticeModel.subtitle,
                        body: ConsentBottomSheetModel.Body(
                            bullets: dataAccessNoticeModel.body.bullets
                        ),
                        extraNotice: dataAccessNoticeModel.connectedAccountNotice,
                        learnMore: dataAccessNoticeModel.learnMore,
                        cta: dataAccessNoticeModel.cta
                    )
                    ConsentBottomSheetViewController.present(
                        withModel: consentBottomSheetModel,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                } else if urlHost == "legal-details-notice" {
                    let legalDetailsNoticeModel = dataSource.consent.legalDetailsNotice
                    let consentBottomSheetModel = ConsentBottomSheetModel(
                        title: legalDetailsNoticeModel.title,
                        subtitle: nil,
                        body: ConsentBottomSheetModel.Body(
                            bullets: legalDetailsNoticeModel.body.bullets
                        ),
                        extraNotice: nil,
                        learnMore: legalDetailsNoticeModel.learnMore,
                        cta: legalDetailsNoticeModel.cta
                    )
                    ConsentBottomSheetViewController.present(
                        withModel: consentBottomSheetModel,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                }
            }
        )
    }
}
