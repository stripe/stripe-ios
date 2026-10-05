//
//  HTMLConfirmationViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 8/27/26.
//

@_spi(STP) import StripeCore
import UIKit

/// Displays an HTML confirmation screen in a Link-styled bottom sheet.
@MainActor
final class HTMLConfirmationViewController {

    private weak var contentViewController: HTMLConfirmationContentViewController?

    let sheetContainer: any PaymentSheetContainer

    /// Closure called when the customer takes action on the confirmation screen.
    var onResult: ((HTMLConfirmationResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
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
        sheetContainer = LinkSheetContainerFactory.make(contentViewController: contentViewController)
        appearance.style.configure(sheetContainer)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        sheetContainer.dismiss(animated: animated, completion: completion)
    }
}
