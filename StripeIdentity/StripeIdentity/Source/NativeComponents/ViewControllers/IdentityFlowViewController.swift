//
//  IdentityFlowViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//

import UIKit
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class IdentityFlowViewController: UIViewController {
    private(set) weak var sheetController: VerificationSheetControllerProtocol?

    private let flowView = IdentityFlowView()

    private var navBarBackgroundColor: UIColor?

    // MARK: Overridable Properties

    /// If non-nil, displays an alert with this configuration when the user attempts to hit the back button.
    var warningAlertViewModel: WarningAlertViewModel? {
        return nil
    }

    // MARK: Init

    init(
        sheetController: VerificationSheetControllerProtocol,
        shouldShowCancelButton: Bool = true
    ) {
        self.sheetController = sheetController
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

    required init?(coder: NSCoder) {
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

    // MARK: Configure
    
    func configure(
        backButtonTitle: String?,
        viewModel: IdentityFlowView.ViewModel
    ) {
        navigationItem.backButtonTitle = backButtonTitle
        flowView.configure(with: viewModel)
        navBarBackgroundColor = viewModel.headerViewModel?.backgroundColor

        if navigationController?.viewControllers.last === self {
            navigationController?.setNavigationBarBackgroundColor(with: navBarBackgroundColor)
        }
    }
}

@available(iOSApplicationExtension, unavailable)
extension IdentityFlowViewController {
    func openInSafariViewController(url: URL) {
        guard url.scheme == "http" || url.scheme == "https" else {
            UIApplication.shared.open(url, options: [:], completionHandler:  nil)
            return
        }

        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .popover
        present(safariVC, animated: true, completion: nil)
    }
}

// MARK: - Private Helpers

private extension IdentityFlowViewController {
    func observeNotifications() {
        // Get keyboard notifications
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func keyboardWillChange(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        flowView.adjustScrollViewForKeyboard(keyboardValue.cgRectValue, isKeyboardHidden: notification.name == UIResponder.keyboardWillHideNotification)
    }

    @objc func didTapCancelButton() {
        dismiss(animated: true, completion: nil)
    }
}
