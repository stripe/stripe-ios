//
//  StreamlinedConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Till Hellmund on 1/20/25.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol StreamlinedConsentViewControllerDelegate: AnyObject {
    func consentViewController(
        _ viewController: StreamlinedConsentViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        nextPaneOrDrawerOnSecondaryCta: String?
    )
    func consentViewController(
        _ viewController: StreamlinedConsentViewController,
        didConsentWithManifest manifest: FinancialConnectionsSessionManifest
    )
}

class StreamlinedConsentViewController: UIViewController {

    private let dataSource: StreamlinedConsentDataSource
    weak var delegate: StreamlinedConsentViewControllerDelegate?
    
    private lazy var footerView: (UIView?, StripeUICore.Button?) = {
        return GenericInfoFooterViewAndPrimaryButton(
            footer: dataSource.consent.screen.footer,
            theme: dataSource.manifest.theme,
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
        view.backgroundColor = .customBackgroundColor
        
        let genericInfoScreen = dataSource.consent.screen
        let theme = dataSource.manifest.theme
        
        let contentView = PaneLayoutView.createContentView(
            iconView: genericInfoScreen.header?.icon?.default.flatMap { imageUrl in
                if imageUrl.contains("BrandIcon") {
                    return CreateRoundedLogoView(urlString: imageUrl)
                } else {
                    return RoundedIconView(
                        image: .imageUrl(imageUrl),
                        style: .circle,
                        theme: theme
                    )
                }
            },
            title: genericInfoScreen.header?.title,
            subtitle: genericInfoScreen.header?.subtitle,
            headerAlignment: {
                let headerAlignment = genericInfoScreen.header?.alignment
                switch headerAlignment {
                case .center:
                    return .center
                case .right:
                    return .trailing
                case .left: fallthrough
                case .unparsable: fallthrough
                case .none:
                    return .leading
                }
            }(),
            contentView: GenericInfoBodyView(
                body: genericInfoScreen.body,
                didSelectURL: didSelectURLInTextFromBackend
            )
        )
        
        let paneLayoutView = PaneLayoutView(contentView: contentView, footerView: footerView.0)
        paneLayoutView.addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .streamlinedConsent)
    }
    
    private func didSelectAgree() {
        dataSource.analyticsClient.log(
            eventName: "click.agree",
            pane: .consent
        )
        
        footerView.1?.isLoading = true

//        footerView.setIsLoading(true)
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
                self.footerView.1?.isLoading = false
//                self.footerView.setIsLoading(false)
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
                            theme: dataSource.manifest.theme,
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
                        theme: dataSource.manifest.theme,
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

// TODO: De-duplicate this with the consent screen
private func CreateRoundedLogoView(urlString: String) -> UIView {
    let cornerRadius: CGFloat = 16.0
    let shadowContainerView = UIView()
    shadowContainerView.layer.shadowColor = UIColor.black.cgColor
    shadowContainerView.layer.shadowOpacity = 0.18
    shadowContainerView.layer.shadowOffset = CGSize(width: 0, height: 3)
    shadowContainerView.layer.shadowRadius = 5
    shadowContainerView.layer.cornerRadius = cornerRadius
    let radius: CGFloat = 72.0
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = cornerRadius
    imageView.setImage(with: urlString)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: radius),
        imageView.heightAnchor.constraint(equalToConstant: radius),
    ])
    shadowContainerView.addAndPinSubview(imageView)
    return shadowContainerView
}
