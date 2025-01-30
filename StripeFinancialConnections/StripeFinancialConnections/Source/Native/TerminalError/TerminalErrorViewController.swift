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
    private let appearance: FinancialConnectionsAppearance
    private let configuration: FinancialConnectionsSheet.Configuration
    weak var delegate: TerminalErrorViewControllerDelegate?

    init(error: Error, allowManualEntry: Bool, appearance: FinancialConnectionsAppearance, configuration: FinancialConnectionsSheet.Configuration) {
        self.error = error
        self.allowManualEntry = allowManualEntry
        self.appearance = appearance
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        navigationItem.hidesBackButton = true

        let terminalErrorView = TerminalErrorView(
            allowManualEntry: allowManualEntry,
            appearance: appearance,
            configuration: configuration,
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
