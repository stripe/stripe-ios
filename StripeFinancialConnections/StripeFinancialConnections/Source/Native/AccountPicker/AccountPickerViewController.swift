//
//  AccountPickerViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
import UIKit

protocol AccountPickerViewControllerDelegate: AnyObject {
    
}

final class AccountPickerViewController: UIViewController {
    
    private let apiClient: FinancialConnectionsAPIClient
    weak var delegate: AccountPickerViewControllerDelegate?
    
    init(apiClient: FinancialConnectionsAPIClient) {
        self.apiClient = apiClient
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
        testLabel.font = .stripeFont(forTextStyle: .subtitle)
        testLabel.text = "Account Picker"
        testLabel.sizeToFit()
        testLabel.center = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
        testLabel.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        view.addSubview(testLabel)
    }
}
