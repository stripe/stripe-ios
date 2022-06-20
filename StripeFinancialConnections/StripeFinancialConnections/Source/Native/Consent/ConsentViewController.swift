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
    
    private let didConsent: () -> Void
    
    init(didConsent: @escaping () -> Void) {
        self.didConsent = didConsent
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let headerView = ConsentHeaderView()
        let bodyView = ConsentBodyView()
        let footerView = ConsentFooterView(didSelectAgree: { [weak self] in
            self?.didConsent()
        })
        
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
