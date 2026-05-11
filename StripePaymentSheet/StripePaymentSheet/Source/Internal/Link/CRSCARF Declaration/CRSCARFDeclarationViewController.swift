//
//  CRSCARFDeclarationViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 4/23/26.
//

import UIKit

/// Container view controller that displays the CRS/CARF declaration in a Link-styled bottom sheet.
final class CRSCARFDeclarationViewController: BottomSheetViewController {
    private weak var contentViewController: CRSCARFDeclarationContentViewController?

    /// Closure called when a user takes action on the declaration.
    var onResult: ((LinkController.CRSCARFDeclarationResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }

    /// Creates a new instance of `CRSCARFDeclarationViewController`.
    /// - Parameters:
    ///   - text: The declaration text to display.
    ///   - appearance: Determines the colors, corner radius, and height of the confirmation button and the user interface style.
    init(text: String, appearance: LinkAppearance) {
        let contentViewController = CRSCARFDeclarationContentViewController(text: text, appearance: appearance)
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

    override func didTapOrSwipeToDismiss() {
        contentViewController?.didTapOrSwipeToDismiss()
    }
}

extension CRSCARFDeclarationContentViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        onResult?(.canceled)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // All content is displayed on a single content view controller with no navigation.
    }
}
