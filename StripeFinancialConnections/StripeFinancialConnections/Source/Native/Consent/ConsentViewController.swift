//
//  ConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/14/22.
//

import Foundation
import UIKit
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
    
    private lazy var footerView: ConsentFooterView = {
        return ConsentFooterView(
            footerText: dataSource.consentModel.footerText,
            didSelectAgree: { [weak self] in
                self?.didSelectAgree()
            },
            didSelectManuallyVerify: dataSource.manifest.allowManualEntry ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.consentViewControllerDidSelectManuallyVerify(self)
            } : nil,
            showManualEntryBusinessDaysNotice: !dataSource.manifest.customManualEntryHandling && dataSource.manifest.manualEntryUsesMicrodeposits
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
        let paneLayoutView = PaneWithHeaderLayoutView(
            title: dataSource.consentModel.headerText,
            contentView: ConsentBodyView(
                bulletItems: dataSource.consentModel.bodyItems,
                dataAccessNoticeModel: dataSource.consentModel.dataAccessNoticeModel
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
}
