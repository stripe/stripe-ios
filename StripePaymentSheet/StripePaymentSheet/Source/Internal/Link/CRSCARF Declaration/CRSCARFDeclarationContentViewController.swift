//
//  CRSCARFDeclarationContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 4/23/26.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// The content view of `CRSCARFDeclarationViewController`, which displays CRS/CARF declaration HTML with a confirmation button.
final class CRSCARFDeclarationContentViewController: UIViewController, BottomSheetContentViewController {

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

    // MARK: - CRSCARFDeclarationContentViewController

    private let html: String
    private let appearance: LinkAppearance
    private let brand: LinkBrand

    private var linkPrimaryButtonColor: UIColor {
        appearance.colors?.primary ?? LinkUI.appearance.primaryButton.backgroundColor ?? LinkUI.appearance.colors.primary
    }

    /// Closure called when a user confirms or cancels the declaration.
    var onResult: ((LinkController.CRSCARFDeclarationResult) -> Void)?

    /// Creates a new instance of `CRSCARFDeclarationContentViewController`.
    /// - Parameters:
    ///   - html: The declaration HTML to display.
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
        label.text = String.Localized.declarations
        label.numberOfLines = 0
        return label
    }()

    private lazy var declarationTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.attributedText = attributedDeclarationHTML
        textView.linkTextAttributes = [
            .foregroundColor: linkPrimaryButtonColor,
        ]
        return textView
    }()

    private var attributedDeclarationHTML: NSAttributedString {
        guard let importedString = try? NSMutableAttributedString(
            data: Data(html.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        ) else {
            return NSAttributedString(string: html, attributes: declarationHTMLAttributes(isLink: false))
        }

        var rangesToUpdate: [(range: NSRange, isLink: Bool)] = []
        let fullRange = NSRange(location: 0, length: importedString.length)
        importedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
            rangesToUpdate.append((range, attributes[.link] != nil))
        }
        rangesToUpdate.forEach { range, isLink in
            importedString.addAttributes(
                declarationHTMLAttributes(isLink: isLink),
                range: range
            )
        }
        return importedString
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
        view.addSubview(declarationTextView)
        view.addSubview(bottomButtonContainer)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: LinkUI.smallContentSpacing),
            headingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            headingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),

            declarationTextView.topAnchor.constraint(equalTo: headingLabel.bottomAnchor, constant: LinkUI.contentSpacing),
            declarationTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: LinkUI.contentSpacing),
            declarationTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -LinkUI.contentSpacing),
            declarationTextView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),

            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func confirmButtonTapped() {
        confirmButton.update(status: .spinnerWithInteractionDisabled)
        onResult?(.confirmed)
    }

    private func declarationHTMLAttributes(isLink: Bool) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2

        return [
            .font: LinkUI.font(forTextStyle: .body),
            .foregroundColor: isLink ? linkPrimaryButtonColor : UIColor.linkTextPrimary,
            .paragraphStyle: paragraphStyle,
        ]
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}

extension CRSCARFDeclarationContentViewController: UITextViewDelegate {

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
