//
//  TerminalErrorViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol TerminalErrorViewControllerDelegate: AnyObject {
    func terminalErrorViewController(_ viewController: TerminalErrorViewController, didCloseWithError error: Error)
}

final class TerminalErrorViewController: UIViewController {
    
    private let error: Error
    weak var delegate: TerminalErrorViewControllerDelegate?
    
    init(error: Error) {
        self.error = error
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        navigationItem.hidesBackButton = true
        
        let errorView = ReusableInformationView(
            iconType: .icon,
            title: STPLocalizedString("Something went wrong", "Title of a screen that shows an error. The error screen appears after user has selected a bank. The error is a generic one: something wrong happened and we are not sure what."),
            subtitle: STPLocalizedString("Your account can't be linked at this time. Please try again later.", "The subtitle/description of a screen that shows an error. The error screen appears after user has selected a bank. The error is a generic one: something wrong happened and we are not sure what."),
            primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                title: "Close", // TODO(kgaidis): once we localize use String.Localized.close
                action: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.terminalErrorViewController(self, didCloseWithError: self.error)
                }
            )
        )
        view.addAndPinSubviewToSafeArea(errorView)
    }
}
