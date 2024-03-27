//
//  IdentityFlowViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class IdentityFlowViewController: UIViewController {
    private(set) weak var sheetController: VerificationSheetControllerProtocol?

    private let flowView = IdentityFlowView()

    private var navBarBackgroundColor: UIColor?

    let analyticsScreenName: IdentityAnalyticsClient.ScreenName

    // MARK: Overridable Properties

    /// If non-nil, displays an alert with this configuration when the user attempts to hit the back button.
    var warningAlertViewModel: WarningAlertViewModel? {
        return nil
    }

    // MARK: Init

    init(
        sheetController: VerificationSheetControllerProtocol,
        analyticsScreenName: IdentityAnalyticsClient.ScreenName,
        shouldShowCancelButton: Bool = true
    ) {
        self.sheetController = sheetController
        self.analyticsScreenName = analyticsScreenName
        super.init(nibName: nil, bundle: nil)

        if shouldShowCancelButton {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: String.Localized.cancel,
                style: .plain,
                target: self,
                action: #selector(didTapCancelButton)
            )
        }
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: UIView Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set flowView as this view controller's view
        flowView.frame = self.view.frame
        self.view = flowView

        observeNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarBackgroundColor(with: navBarBackgroundColor)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.stopTrackingTimeToScreenAndLogIfNeeded(
            to: analyticsScreenName,
            sheetController: sheetController
        )
        sheetController.analyticsClient.logScreenAppeared(
            screenName: analyticsScreenName,
            sheetController: sheetController
        )
    }

    // MARK: Configure

    func configure(
            backButtonTitle: String?,
            viewModel: IdentityFlowView.ViewModel
        ) {
        navigationItem.backButtonTitle = backButtonTitle
        do {
            try flowView.configure(with: viewModel)
        } catch {
            if let sheetController = sheetController {
                sheetController.analyticsClient.logGenericError(error: error, sheetController: sheetController)
            }
        }
        navBarBackgroundColor = viewModel.headerViewModel?.backgroundColor

        if navigationController?.viewControllers.last === self {
            navigationController?.setNavigationBarBackgroundColor(with: navBarBackgroundColor)
        }
    }
}

// MARK: - Private Helpers

extension IdentityFlowViewController {
    fileprivate func observeNotifications() {
        // Get keyboard notifications
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc fileprivate func keyboardWillChange(notification: Notification) {
        guard
            let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? NSValue
        else {
            return
        }
        flowView.adjustScrollViewForKeyboard(
            keyboardValue.cgRectValue,
            isKeyboardHidden: notification.name == UIResponder.keyboardWillHideNotification
        )
    }

    @objc fileprivate func didTapCancelButton() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - parse bottomsheet URL
extension URL {
    func parseBottomSheetID() -> String? {
        let urlString = self.absoluteString

        guard let range = urlString.range(of: "stripe_bottomsheet://open/") else {
            return nil // Return nil if the key is not found in the url string
        }

        // Return the string after the key
        return String(urlString[range.upperBound...])
    }
}

// MARK: - Bottomsheet helpers
extension IdentityFlowViewController {
    fileprivate func logBottomsheetError(_ errorContent: String) {
        if let sheetController = self.sheetController {
            sheetController.analyticsClient.logGenericError(
                error: BottomSheetError(loggableType: errorContent),
                sheetController: sheetController
            )
        }
    }

    func presentBottomsheet(withUrl bottomSheetUrl: URL) {
        guard let bottomSheetID = bottomSheetUrl.parseBottomSheetID()
        else {
            self.logBottomsheetError("error presenting bottomsheet, error parsing id from \(bottomSheetUrl)")
            return
        }
        self.presentBottomsheet(withID: bottomSheetID)
    }

    func presentBottomsheet(withID bottomSheetID: String) {

        guard let verificationPage = try? sheetController?.verificationPageResponse?.get()
        else {
            self.logBottomsheetError("error presenting bottomsheet, can't get VerficationPageResponse")
            return

        }

        guard let bottomSheetContent = verificationPage.bottomsheet?[bottomSheetID]
        else {
            self.logBottomsheetError("error presenting bottomsheet, can't find bottomsheet with \(bottomSheetID)")
            return
        }
        do {
            try self.presentBottomsheet(withContent: bottomSheetContent)
        } catch {
            self.logBottomsheetError("error presenting bottomsheet, fail to present bottomsheet with \(bottomSheetID)")
        }
    }

    func presentBottomsheet(
        withContent content: BottomSheetViewController.BottomSheetContent
    ) throws {
        let consentBottomSheetViewController = try BottomSheetViewController(
            content: content
        )
        consentBottomSheetViewController.modalTransitionStyle = .coverVertical
        consentBottomSheetViewController.modalPresentationStyle = .pageSheet
        self.present(consentBottomSheetViewController, animated: true, completion: nil)
    }
}
