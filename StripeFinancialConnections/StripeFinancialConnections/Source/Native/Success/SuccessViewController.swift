//
//  SuccessViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/12/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol SuccessViewControllerDelegate: AnyObject {
    func successViewController(
        _ viewController: SuccessViewController,
        didCompleteSession session: StripeAPI.FinancialConnectionsSession
    )
}

final class SuccessViewController: UIViewController {
    
    private let dataSource: SuccessDataSource
    weak var delegate: SuccessViewControllerDelegate?
    
    init(dataSource: SuccessDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        
        let testSuccessDoneButton = UIButton(type: .system)
        testSuccessDoneButton.setTitle("Success! Press to finish.", for: .normal)
        testSuccessDoneButton.addTarget(self, action: #selector(didSelectDone), for: .touchUpInside)
        testSuccessDoneButton.sizeToFit()
        testSuccessDoneButton.center = CGPoint(x: view.bounds.width/2, y: view.bounds.height/2)
        testSuccessDoneButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        view.addSubview(testSuccessDoneButton)
    }
    
    @objc private func didSelectDone() {
        dataSource.completeFinancialConnectionsSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let session):
                    self.delegate?.successViewController(self, didCompleteSession: session)
                case .failure(let error):
                    print(error) // TODO(kgaidis): handle error properly
                }
            }
    }
}
