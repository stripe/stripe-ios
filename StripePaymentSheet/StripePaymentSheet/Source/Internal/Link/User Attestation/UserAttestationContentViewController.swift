//
//  UserAttestationContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 4/23/26.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
#if canImport(UIKit)
import UIKit
#else
import Foundation
#endif

/// The content view of `UserAttestationViewController`, which displays user attestation HTML with a confirmation button.
final class UserAttestationContentViewController: UIViewController, BottomSheetContentViewController {

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

    // MARK: - UserAttestationContentViewController

    private let html: String
    private let appearance: LinkAppearance
    private let brand: LinkBrand

    private var linkPrimaryButtonColor: UIColor {
        appearance.colors?.primary ?? LinkUI.appearance.primaryButton.backgroundColor ?? LinkUI.appearance.colors.primary
    }

    private var attestationBaseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: LinkUI.font(forTextStyle: .body),
            .foregroundColor: UIColor.linkTextPrimary,
        ]
    }

    private var attestationLinkAttributes: [NSAttributedString.Key: Any] {
        [
            .foregroundColor: linkPrimaryButtonColor,
        ]
    }

    /// Closure called when a user confirms or cancels the attestation.
    var onResult: ((LinkController.UserAttestationResult) -> Void)?

    /// Creates a new instance of `UserAttestationContentViewController`.
    /// - Parameters:
    ///   - html: The attestation HTML to display.
    ///   - appearance: Determines the colors, corner radius, and height of the confirmation button.
    init(html: String, appearance: LinkAppearance, brand: LinkBrand) {
        self.html = html
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
        label.text = String.Localized.user_attestation
        label.numberOfLines = 0
        return label
    }()

    private lazy var attestationTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.attributedText = attributedAttestationHTML
        textView.linkTextAttributes = [
            .foregroundColor: linkPrimaryButtonColor,
        ]
        return textView
    }()

    private var attributedAttestationHTML: NSAttributedString {
        guard let attributedString = try? NSMutableAttributedString(
            data: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) else {
            return NSAttributedString(string: html, attributes: attestationBaseAttributes)
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        var linkRanges: [NSRange] = []
        attributedString.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            if value != nil {
                linkRanges.append(range)
            }
        }

        attributedString.addAttributes(attestationBaseAttributes, range: fullRange)

        // Processing the HTML via NSAttributedString applies paragraph style properties. We need to apply our line height multiple to each of these
        // paragraph styles individually, as setting the paragraph style for the entire range will overwrite other formatting aspects from the HTML,
        // such as lists/bullet points and indentation.
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
            attributedString.addAttributes(attestationLinkAttributes, range: range)
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
        callToAction: .custom(title: String.Localized.accept),
        showProcessingLabel: false,
        linkAppearance: appearance
    ) { [weak self] in
        self?.confirmButtonTapped()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(headingLabel)
        view.addSubview(attestationTextView)
        view.addSubview(bottomButtonContainer)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: LinkUI.smallContentSpacing),
            headingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            headingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),

            attestationTextView.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: LinkUI.contentSpacing),
            attestationTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            attestationTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),
            attestationTextView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),

            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func confirmButtonTapped() {
        confirmButton.update(status: .spinnerWithInteractionDisabled)
        onResult?(.confirmed)
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}

extension UserAttestationContentViewController: UITextViewDelegate {

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
