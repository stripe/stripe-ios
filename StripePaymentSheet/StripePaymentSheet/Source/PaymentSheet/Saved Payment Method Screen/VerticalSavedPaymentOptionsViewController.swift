//
//  VerticalSavedPaymentOptionsViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentOptionsViewController: UIViewController {

    private let configuration: PaymentSheet.Configuration

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back)
        navBar.delegate = self
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = .Localized.select_your_payment_method
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = PaymentSheetUI.defaultPadding
        return stackView
    }()

    init(configuration: PaymentSheet.Configuration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: 0, trailing: PaymentSheetUI.defaultSheetMargins.bottom))
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentOptionsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        // TODO
        return true
    }

    func didTapOrSwipeToDismiss() {
        dismiss(animated: true)
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentOptionsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = bottomSheetController?.popContentViewController()
    }
}
