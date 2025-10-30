//
//  VerifyKYCViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/28/25.
//

@_spi(STP) import StripePaymentSheet

import UIKit

/// Container view controller that displays a list of KYC fields with the optional ability to initiate editing of the address.
final class VerifyKYCViewController: BottomSheetViewController {
    private enum Constants {
        static let sheetCornerRadius: CGFloat = 24
    }

    private weak var contentViewController: VerifyKYCContentViewController?

    /// Closure called when a user takes action (confirm, cancel, or initiate editing of the address).
    var onResult: ((VerifyKycResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    // MARK: - BottomSheetViewController

    override var sheetCornerRadius: CGFloat? {
        Constants.sheetCornerRadius
    }

    // MARK: - VerifyKYCViewController

    /// Creates a new instance of `VerifyKYCViewController`.
    /// - Parameters:
    ///   - info: The KYC information to display.
    ///   - appearance: Determines the colors, corner radius, and height of the "Confirm" button and the user interface style (i.e. light, dark, or system).
    init(info: KYCRefreshInfo, appearance: LinkAppearance) {
        let contentViewController = VerifyKYCContentViewController(info: info, appearance: appearance)
        self.contentViewController = contentViewController

        super.init(
            contentViewController: contentViewController,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: {}
        )

        appearance.style.configure(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(contentViewController: any BottomSheetContentViewController, appearance: PaymentSheet.Appearance, isTestMode: Bool, didCancelNative3DS2: @escaping () -> Void) {
        fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
    }

    // MARK: - BottomSheetViewController

    override func didTapOrSwipeToDismiss() {
        contentViewController?.didTapOrSwipeToDismiss()
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
