//
//  VerifyKYCViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 10/28/25.
//

import UIKit

/// Container view controller that displays a list of KYC fields with the optional ability to initiate editing of the address.
@MainActor
final class VerifyKYCViewController {

    private weak var contentViewController: VerifyKYCContentViewController?
    // The presented container owns the content, so keep this coordinator alive until dismissal completes.
    private var selfRetainer: VerifyKYCViewController?

    let sheetContainer: any PaymentSheetContainer

    /// Closure called when a user takes action (confirm, cancel, or initiate editing of the address).
    var onResult: ((VerifyKYCResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    // MARK: - VerifyKYCViewController

    /// Creates a new instance of `VerifyKYCViewController`.
    /// - Parameters:
    ///   - info: The KYC information to display.
    ///   - appearance: Determines the colors, corner radius, and height of the "Confirm" button and the user interface style (i.e. light, dark, or system).
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
