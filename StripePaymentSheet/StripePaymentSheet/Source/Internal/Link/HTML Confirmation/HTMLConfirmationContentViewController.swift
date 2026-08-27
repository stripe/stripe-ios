//
//  HTMLConfirmationContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 8/27/26.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Displays HTML content with a configurable heading and confirmation button.
final class HTMLConfirmationContentViewController: UIViewController, BottomSheetContentViewController {

    // MARK: - BottomSheetContentViewController

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: .default,
            brand: brand,
            shouldLogPaymentSheetAnalyticsOnDismissal: false
        )
        navigationBar.setStyle(.close(showAdditionalButton: false))
        navigationBar.delegate = self
        return navigationBar
    }()

    let requiresFullScreen = false

    // MARK: - HTMLConfirmationContentViewController

    private let heading: String
    private let html: String
    private let confirmationButtonTitle: String
    private let appearance: LinkAppearance
    private let brand: LinkBrand

    private var linkPrimaryButtonColor: UIColor {
        appearance.colors?.primary ?? LinkUI.appearance.primaryButton.backgroundColor ?? LinkUI.appearance.colors.primary
    }

    private var htmlBaseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: LinkUI.font(forTextStyle: .body),
            .foregroundColor: UIColor.linkTextPrimary,
        ]
    }

    private var htmlLinkAttributes: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: linkPrimaryButtonColor,
        ]
    }

    /// Closure called when a customer confirms or cancels.
    var onResult: ((HTMLConfirmationResult) -> Void)?

    /// Creates a new HTML confirmation content view controller.
    /// - Parameters:
    ///   - heading: The heading displayed above the HTML.
    ///   - html: The HTML to display.
    ///   - confirmationButtonTitle: The title of the confirmation button.
    ///   - appearance: Determines the colors, corner radius, and height of the confirmation button.
    ///   - brand: The Link brand displayed in the navigation bar.
    init(
        heading: String,
        html: String,
        confirmationButtonTitle: String,
        appearance: LinkAppearance,
        brand: LinkBrand
    ) {
        self.heading = heading
        self.html = html
        self.confirmationButtonTitle = confirmationButtonTitle
        self.appearance = appearance
        self.brand = brand
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
        label.text = heading
        label.numberOfLines = 0
        return label
    }()

    private lazy var htmlTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.attributedText = attributedHTML
        textView.linkTextAttributes = [
            .foregroundColor: linkPrimaryButtonColor,
        ]
        return textView
    }()

    private var attributedHTML: NSAttributedString {
        guard let attributedString = try? NSMutableAttributedString(
            data: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) else {
            return NSAttributedString(string: html, attributes: htmlBaseAttributes)
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        var linkRanges: [NSRange] = []
        attributedString.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            if value != nil {
                linkRanges.append(range)
            }
        }

        attributedString.addAttributes(htmlBaseAttributes, range: fullRange)

        // Processing the HTML via NSAttributedString applies paragraph style properties. Apply
        // the line height to each style individually to preserve lists, indentation, and other
        // formatting from the HTML.
        var paragraphStyles: [(style: NSMutableParagraphStyle, range: NSRange)] = []
        attributedString.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.2
            paragraphStyles.append((paragraphStyle, range))
        }

        paragraphStyles.forEach { style, range in
            attributedString.addAttribute(.paragraphStyle, value: style, range: range)
        }
        linkRanges.forEach { range in
            attributedString.addAttributes(htmlLinkAttributes, range: range)
        }

        return attributedString
    }

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubviewToSafeArea(confirmButton, insets: .insets(amount: LinkUI.contentSpacing))
        return view
    }()

    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: confirmationButtonTitle),
        showProcessingLabel: false,
        linkAppearance: appearance
    ) { [weak self] in
        self?.confirmButtonTapped()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(headingLabel)
        view.addSubview(htmlTextView)
        view.addSubview(bottomButtonContainer)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: LinkUI.smallContentSpacing),
            headingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            headingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),

            htmlTextView.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: LinkUI.contentSpacing),
            htmlTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            htmlTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),
            htmlTextView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),

            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func confirmButtonTapped() {
        confirmButton.update(status: .spinnerWithInteractionDisabled)
        onResult?(.confirmed)
    }

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}

extension HTMLConfirmationContentViewController: UITextViewDelegate {

    // MARK: - UITextViewDelegate

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard interaction == .invokeDefaultAction else {
            return false
        }

        if ["http", "https"].contains(URL.scheme?.lowercased()) {
            let safariViewController = SFSafariViewController(url: URL)
            #if !os(visionOS)
            safariViewController.dismissButtonStyle = .close
            #endif
            safariViewController.modalPresentationStyle = .overFullScreen
            present(safariViewController, animated: true)
        }

        return false
    }
}

extension HTMLConfirmationContentViewController: SheetNavigationBarDelegate {

    // MARK: - SheetNavigationBarDelegate

    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        onResult?(.canceled)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // All content is displayed on a single content view controller with no navigation.
    }
}
