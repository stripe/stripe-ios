//
//  HTMLConfirmationViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 8/27/26.
//

@_spi(STP) import StripeCore
import UIKit

/// Displays an HTML confirmation screen in a Link-styled bottom sheet.
final class HTMLConfirmationViewController: BottomSheetViewController {
    private weak var contentViewController: HTMLConfirmationContentViewController?

    /// Closure called when the customer takes action on the confirmation screen.
    var onResult: ((HTMLConfirmationResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    override var sheetCornerRadius: CGFloat? {
        LinkUI.largeCornerRadius
    }

    /// Creates a new HTML confirmation view controller.
    /// - Parameters:
    ///   - heading: The heading displayed above the HTML.
    ///   - html: The HTML to display.
    ///   - confirmationButtonTitle: The title of the confirmation button.
    ///   - appearance: Determines the colors, corner radius, button height, and user interface style.
    ///   - brand: The Link brand displayed in the navigation bar.
    init(
        heading: String,
        html: String,
        confirmationButtonTitle: String,
        appearance: LinkAppearance,
        brand: LinkBrand
    ) {
        let contentViewController = HTMLConfirmationContentViewController(
            heading: heading,
            html: html,
            confirmationButtonTitle: confirmationButtonTitle,
            appearance: appearance,
            brand: brand
        )
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

    required init(
        contentViewController: any BottomSheetContentViewController,
        appearance: PaymentSheet.Appearance,
        isTestMode: Bool,
        didCancelNative3DS2: @escaping () -> Void
    ) {
        fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
    }

    override func didTapOrSwipeToDismiss() {
        contentViewController?.didTapOrSwipeToDismiss()
    }
}
