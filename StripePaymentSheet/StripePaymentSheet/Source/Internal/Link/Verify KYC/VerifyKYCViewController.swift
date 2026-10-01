//
//  VerifyKYCViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 10/28/25.
//

import UIKit

/// Owns the presentation container for Link KYC verification.
@MainActor
final class VerifyKYCViewController {

    private weak var contentViewController: VerifyKYCContentViewController?
    // The presented container owns the content, so keep this coordinator alive until dismissal completes.
    private var selfRetainer: VerifyKYCViewController?

    let sheetContainer: any PaymentSheetContainer

    var onResult: ((VerifyKYCResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    /// Creates a new instance of `VerifyKYCViewController`.
    /// - Parameters:
    ///   - info: The KYC information to display.
    ///   - appearance: Determines the colors, corner radius, and height of the "Confirm" button and the user interface style.
    init(info: VerifyKYCInfo, appearance: LinkAppearance) {
        let contentViewController = VerifyKYCContentViewController(info: info, appearance: appearance)
        self.contentViewController = contentViewController
        sheetContainer = LinkSheetContainerFactory.make(contentViewController: contentViewController)
        appearance.style.configure(sheetContainer)
        selfRetainer = self
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        sheetContainer.dismiss(animated: animated) { [self] in
            selfRetainer = nil
            completion?()
        }
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
