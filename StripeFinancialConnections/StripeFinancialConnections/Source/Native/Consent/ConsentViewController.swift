//
//  ConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/14/22.
//

import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

@available(iOSApplicationExtension, unavailable)
protocol ConsentViewControllerDelegate: AnyObject {
    func consentViewControllerDidSelectManuallyVerify(_ viewController: ConsentViewController)
    func consentViewController(_ viewController: ConsentViewController, didConsentWithManifest manifest: FinancialConnectionsSessionManifest)
}

@available(iOSApplicationExtension, unavailable)
class ConsentViewController: UIViewController {
    
    private let dataSource: ConsentDataSource
    weak var delegate: ConsentViewControllerDelegate?
    
    private lazy var titleLabel: ClickableLabel = {
        let titleLabel = ClickableLabel(
            font: .stripeFont(forTextStyle: .subtitle),
            boldFont: .stripeFont(forTextStyle: .subtitle),
            linkFont: .stripeFont(forTextStyle: .subtitle),
            textColor: .textPrimary
        )
        titleLabel.setText(
            dataSource.consent.title,
            action: { [weak self] url in
                // there are no known cases where we add a link to the title
                // but we add this handling regardless in case this changes
                // in the future
                self?.didSelectURL(url)
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
                self?.didSelectURL(url)
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
            headerView: titleLabel,
            contentView: ConsentBodyView(
                bulletItems: dataSource.consent.body.bullets,
                didSelectURL: { [weak self] url in
                    self?.didSelectURL(url)
                }
            ),
            footerView: footerView
        )
        paneLayoutView.addTo(view: view)
        
        dataSource.analyticsClient.logPaneLoaded(pane: .consent)
    }
    
    private func didSelectAgree() {
        dataSource.analyticsClient.log(
            eventName: "click.agree",
            parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.consent.rawValue]
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
    
    // this function will get called when user taps
    // on ANY link returned from backend
    private func didSelectURL(_ url: URL) {
        if
            let urlParameters = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let eventName = urlParameters.queryItems?.first(where: { $0.name == "eventName" })?.value
        {
            dataSource
                .analyticsClient
                .log(
                    eventName: eventName,
                    parameters: ["pane": FinancialConnectionsSessionManifest.NextPane.consent.rawValue]
                )
        }
        
        if url.scheme == "stripe" {
            if url.host == "manual-entry" {
                delegate?.consentViewControllerDidSelectManuallyVerify(self)
            } else if url.host == "data-access-notice" {
                let dataAccessNoticeModel = dataSource.consent.dataAccessNotice
                let consentBottomSheetModel = ConsentBottomSheetModel(
                    title: dataAccessNoticeModel.title,
                    body: ConsentBottomSheetModel.Body(
                        bullets: dataAccessNoticeModel.body.bullets
                    ),
                    extraNotice: dataAccessNoticeModel.connectedAccountNotice,
                    learnMore: dataAccessNoticeModel.learnMore,
                    cta: dataAccessNoticeModel.cta
                )
                PresentConsentBottomSheet(
                    withModel: consentBottomSheetModel,
                    didSelectUrl: { [weak self] url in
                        self?.didSelectURL(url)
                    }
                )
            }
        } else {
            SFSafariViewController.present(url: url)
        }
    }
}

@available(iOSApplicationExtension, unavailable)
private func PresentConsentBottomSheet(
    withModel model: ConsentBottomSheetModel,
    didSelectUrl: @escaping (URL) -> Void
) {
    let consentBottomSheetViewController = ConsentBottomSheetViewController(
        model: model,
        didSelectURL: didSelectUrl
    )
    consentBottomSheetViewController.modalTransitionStyle = .crossDissolve
    consentBottomSheetViewController.modalPresentationStyle = .overCurrentContext
    // `false` for animations because we do a custom animation inside VC logic
    UIViewController
        .topMostViewController()?
        .present(consentBottomSheetViewController, animated: false, completion: nil)
}
