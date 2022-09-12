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
class ConsentViewController: UIViewController {
    
    private let manifest: FinancialConnectionsSessionManifest
    private let consentModel: ConsentModel
    private let didConsent: () -> Void
    private let didSelectManuallyVerify: (() -> Void)?
    
    init(
        manifest: FinancialConnectionsSessionManifest,
        consentModel: ConsentModel =  ConsentModel(),
        didConsent: @escaping () -> Void,
        didSelectManuallyVerify: (() -> Void)? // null if manual entry disabled
    ) {
        self.manifest = manifest
        self.consentModel = consentModel
        self.didConsent = didConsent
        self.didSelectManuallyVerify = didSelectManuallyVerify
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        let paneLayoutView = PaneWithHeaderLayoutView(
            title: consentModel.headerText,
            contentView: ConsentBodyView(
                bulletItems: consentModel.bodyItems,
                dataAccessNoticeModel: consentModel.dataAccessNoticeModel
            ),
            footerView: ConsentFooterView(
                footerText: consentModel.footerText,
                didSelectAgree: { [weak self] in
                    self?.didConsent()
                },
                didSelectManuallyVerify: didSelectManuallyVerify,
                showManualEntryBusinessDaysNotice: !manifest.customManualEntryHandling && manifest.manualEntryUsesMicrodeposits
            )
        )
        paneLayoutView.addToView(view)
    }
}
