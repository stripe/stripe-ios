//
//  AccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol AccountPickerViewControllerDelegate: AnyObject {
    
}

final class AccountPickerViewController: UIViewController {
    
    private let dataSource: AccountPickerDataSource
    weak var delegate: AccountPickerViewControllerDelegate?
    
    init(dataSource: AccountPickerDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        
        let testLabel = UILabel()
        testLabel.textColor = .textPrimary
        testLabel.font = .stripeFont(forTextStyle: .body)
        testLabel.text = "Retreiving Accounts..."
        testLabel.sizeToFit()
        testLabel.frame = view.bounds
        testLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        testLabel.textAlignment = .center
        testLabel.numberOfLines = 0
        view.addSubview(testLabel)
        
        dataSource
            .pollAuthSessionAccounts()
            .observe(on: .main) { result in
                switch result {
                case .success(let accounts):
                    testLabel.text = accounts.data.reduce("", { $0 + $1.name + "\n" })
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle all sorts of errors...
                }
            }
    }
}
