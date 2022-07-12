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

class ConsentViewController: UIViewController {
    
    private let consentModel: ConsentModel
    private let didConsent: () -> Void
    
    init(
        consentModel: ConsentModel =  ConsentModel(),
        didConsent: @escaping () -> Void
    ) {
        self.consentModel = consentModel
        self.didConsent = didConsent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let headerView = ConsentHeaderView(text: consentModel.headerText)
        let bodyView = ConsentBodyView(bulletItems: consentModel.bodyItems)
        let footerView = ConsentFooterView(
            footerText: consentModel.footerText,
            didSelectAgree: { [weak self] in
                self?.didConsent()
            }
        )
        
        let stackView = UIStackView(arrangedSubviews: [
            headerView,
            bodyView,
            footerView,
        ])
        stackView.axis = .vertical
        stackView.spacing = 0
        view.addAndPinSubview(stackView)
    }
}
