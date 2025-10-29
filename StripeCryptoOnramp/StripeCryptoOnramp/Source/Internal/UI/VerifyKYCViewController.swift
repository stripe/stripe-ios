//
//  VerifyKYCViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/28/25.
//

import UIKit
import SwiftUI
@_spi(STP) import StripePaymentSheet

final class VerifyKYCViewController: BottomSheetViewController {
    private let info: KYCRefreshInfo
    private weak var contentViewController: VerifyKYCContentViewController?

    var onResult: ((VerifyKycResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    override var sheetCornerRadius: CGFloat? {
        24
    }

    // TODO: also take `LinkAppearance` on init.
    init(info: KYCRefreshInfo) {
        self.info = info

        let contentViewController = VerifyKYCContentViewController(info: info)
        self.contentViewController = contentViewController

        super.init(
            contentViewController: contentViewController,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: {}
        )
    }

    override func didTapOrSwipeToDismiss() {
        contentViewController?.didTapOrSwipeToDismiss()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(contentViewController: any BottomSheetContentViewController, appearance: PaymentSheet.Appearance, isTestMode: Bool, didCancelNative3DS2: @escaping () -> Void) {
        fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
    }
}

extension VerifyKYCContentViewController: SheetNavigationBarDelegate {

    // MARK: - SheetNavigationBarDelegate

    func sheetNavigationBarDidClose(_ sheetNavigationBar: StripePaymentSheet.SheetNavigationBar) {
        onResult?(.canceled)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: StripePaymentSheet.SheetNavigationBar) {
        // All content is displayed on a single content view controller with no navigation.
    }
}

final class VerifyKYCContentViewController: UIViewController, BottomSheetContentViewController {

    // MARK: - BottomSheetContentViewController

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(isTestMode: false, appearance: .default)
        navigationBar.setStyle(.close(showAdditionalButton: false))
        navigationBar.delegate = self
        return navigationBar
    }()

    let requiresFullScreen: Bool = true

    // MARK: - VerifyKYCContentViewController

    private let info: KYCRefreshInfo
    var onResult: ((VerifyKycResult) -> Void)?

    init(info: KYCRefreshInfo) {
        self.info = info
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = "Confirm your information"
        return label
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headingLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground


    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}
