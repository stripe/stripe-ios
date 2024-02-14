//
//  TerminalErrorViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/15/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol TerminalErrorViewControllerDelegate: AnyObject {
    func terminalErrorViewController(_ viewController: TerminalErrorViewController, didCloseWithError error: Error)
    func terminalErrorViewControllerDidSelectManualEntry(_ viewController: TerminalErrorViewController)
}

final class TerminalErrorViewController: UIViewController {

    private let error: Error
    private let allowManualEntry: Bool
    weak var delegate: TerminalErrorViewControllerDelegate?

    init(error: Error, allowManualEntry: Bool) {
        self.error = error
        self.allowManualEntry = allowManualEntry
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        navigationItem.hidesBackButton = true

        let terminalErrorView = TerminalErrorView(
            allowManualEntry: true,
            didSelectManualEntry: { [weak self] in
                guard let self = self else { return }
                self.delegate?.terminalErrorViewControllerDidSelectManualEntry(self)
            },
            didSelectClose: { [weak self] in
                guard let self = self else { return }
                self.delegate?.terminalErrorViewController(self, didCloseWithError: self.error)
            }
        )
        view.addAndPinSubview(terminalErrorView)
    }
}
