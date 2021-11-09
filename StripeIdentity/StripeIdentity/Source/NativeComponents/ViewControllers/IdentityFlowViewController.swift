//
//  IdentityFlowViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//

import UIKit
@_spi(STP) import StripeCore

class IdentityFlowViewController: UIViewController {

    private(set) weak var sheetController: VerificationSheetControllerProtocol?

    private let flowView = IdentityFlowView()

    init(sheetController: VerificationSheetControllerProtocol) {
        self.sheetController = sheetController
        super.init(nibName: nil, bundle: nil)

        // Add close button to navbar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: String.Localized.close,
            style: .plain,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set flowView as this view controller's view
        flowView.frame = self.view.frame
        self.view = flowView

        observeNotifications()
    }

    func configure(
        title: String?,
        backButtonTitle: String?,
        viewModel: IdentityFlowView.ViewModel
    ) {
        self.title = title
        navigationItem.backButtonTitle = backButtonTitle
        flowView.configure(with: viewModel)
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

    @objc func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}
