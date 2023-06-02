//
//  CloseConfirmationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/6/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class CloseConfirmationSheetViewController: UIViewController {

    private let didSelectClose: () -> Void
    private let sheetCommunicationHelper: CustomSheetCommunicationHelper

    fileprivate init(
        didSelectClose: @escaping () -> Void,
        communicationHelper: CustomSheetCommunicationHelper
    ) {
        self.didSelectClose = didSelectClose
        self.sheetCommunicationHelper = communicationHelper
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let customSheetView = CustomSheetView(
            iconType: .systemIcon(.panel_arrow_right),
            title: STPLocalizedString(
                "Sure you want to exit?",
                "The title of a sheet that appears when the user attempts to exit the bank linking screen."
            ),
            subtitle: STPLocalizedString(
                "You haven't finished linking your bank account and all progress will be lost.",
                "The subtitle/description of a sheet that appears when the user attempts to exit the bank linking screen."
            ),
            contentView: nil,
            primaryButtonConfiguration: CustomSheetView.ButtonConfiguration(
                title: STPLocalizedString(
                    "Yes, exit",
                    "A button title. The user encounters it as part of a confirmation sheet when trying to exit a screen. Pressing it will exit the screen, and cancel the process of connecting the users bank account."
                ),
                action: { [weak self] in
                    guard let self = self else { return }
                    self.sheetCommunicationHelper.dismissSheet {
                        // call `didSelectClose` AFTER we dismiss the
                        // sheet to ensure we don't have bugs where
                        // a view controller is in process of dismissing
                        // while we are trying to present/dismiss another
                        self.didSelectClose()
                    }
                }
            ),
            secondaryButtonConfiguration: CustomSheetView.ButtonConfiguration(
                title: STPLocalizedString(
                    "No, continue",
                    "A button title. The user encounters it as part of a confirmation pop-up when trying to exit a screen. Pressing it will close the pop-up, and will ensure that the screen does NOT exit."
                ),
                action: { [weak self] in
                    self?.sheetCommunicationHelper.dismissSheet()
                }
            )
        )
        view.addAndPinSubview(customSheetView)
    }

    // MARK: - Presenting Logic

    static func present(
        didSelectClose: @escaping () -> Void
    ) {
        let communicationHelper = CustomSheetCommunicationHelper()
        let closeConfirmationViewController = CloseConfirmationSheetViewController(
            didSelectClose: didSelectClose,
            communicationHelper: communicationHelper
        )
        closeConfirmationViewController.presentAsSheet(communicationHelper: communicationHelper)
    }
}
