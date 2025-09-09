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
    func consentViewController(
        _ viewController: ConsentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    )
    func consentViewController(
        _ viewController: ConsentViewController,
        didConsentWithResult result: ConsentAcquiredResult
    )
    func consentViewControllerDidFailAttestationVerdict(
        _ viewController: ConsentViewController,
        prefillDetails: WebPrefillDetails
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
            textColor: FinancialConnectionsAppearance.Colors.textDefault,
            alignment: .center
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
            appearance: dataSource.manifest.appearance,
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
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background

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
                    let showsAnimatedDots = dataSource.manifest.isLinkWithStripe != true
                    let consentLogoView = ConsentLogoView(
                        merchantLogo: merchantLogo,
                        showsAnimatedDots: showsAnimatedDots
                    )
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // this fixes an issue where presenting a UIViewController
        // on top of ConsentViewController would stop the dot animation
        consentLogoView?.animateDots()
    }

    @objc private func appWillEnterForeground() {
        // Fixes an issue where the dot animation was stopped when the app
        // was backgrounded, then reopened.
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
                case .success(let result):
                    self.delegate?.consentViewController(self, didConsentWithResult: result)
                case .failure(let error):
                    let attestationError = self.dataSource.completeAssertionIfNeeded(
                        possibleError: error,
                        api: .consumerSessionLookup
                    )

                    if attestationError != nil {
                        let prefillDetails = WebPrefillDetails(email: dataSource.email)
                        self.delegate?.consentViewControllerDidFailAttestationVerdict(self, prefillDetails: prefillDetails)
                    }

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
            handleURL: { urlHost, nextPaneOrDrawerOnSecondaryCta in
                guard let urlHost, let address = StripeSchemeAddress(rawValue: urlHost) else {
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            FinancialConnectionsSheetError.unknown(
                                debugDescription: "Unknown Stripe-scheme URL detected: \(urlHost ?? "nil")."
                            ),
                            errorName: "ConsentStripeURLError",
                            pane: .consent
                        )
                    return
                }

                switch address {
                case .manualEntry:
                    delegate?.consentViewController(
                        self,
                        didRequestNextPane: .manualEntry,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                case .dataAccessNotice:
                    if let dataAccessNotice = dataSource.consent.dataAccessNotice {
                        let dataAccessNoticeViewController = DataAccessNoticeViewController(
                            dataAccessNotice: dataAccessNotice,
                            appearance: dataSource.manifest.appearance,
                            didSelectUrl: { [weak self] url in
                                self?.didSelectURLInTextFromBackend(url)
                            }
                        )
                        dataAccessNoticeViewController.present(on: self)
                    }
                case .legalDatailsNotice:
                    let legalDetailsNoticeModel = dataSource.consent.legalDetailsNotice
                    let legalDetailsNoticeViewController = LegalDetailsNoticeViewController(
                        legalDetailsNotice: legalDetailsNoticeModel,
                        appearance: dataSource.manifest.appearance,
                        didSelectUrl: { [weak self] url in
                            self?.didSelectURLInTextFromBackend(url)
                        }
                    )
                    legalDetailsNoticeViewController.present(on: self)
                case .linkAccountPicker:
                    delegate?.consentViewController(
                        self,
                        didRequestNextPane: .linkAccountPicker,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                case .linkLogin:
                    delegate?.consentViewController(
                        self,
                        didRequestNextPane: .networkingLinkLoginWarmup,
                        nextPaneOrDrawerOnSecondaryCta: nextPaneOrDrawerOnSecondaryCta
                    )
                }
            }
        )
    }
}
