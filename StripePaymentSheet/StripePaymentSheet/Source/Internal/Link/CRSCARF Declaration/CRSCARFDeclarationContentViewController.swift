//
//  CRSCARFDeclarationContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 4/23/26.
//

@_spi(STP) import StripeUICore
import UIKit

/// The content view of `CRSCARFDeclarationViewController`, which displays CRS/CARF declaration text with a confirmation button.
final class CRSCARFDeclarationContentViewController: UIViewController, BottomSheetContentViewController {
    // TODO(Localization): Localize the declaration heading and CTA copy.
    // TODO(Figma): Confirm the final spacing and typography values against the latest CRS/CARF Figma.

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: .default,
            shouldLogPaymentSheetAnalyticsOnDismissal: false
        )
        navigationBar.setStyle(.close(showAdditionalButton: false))
        navigationBar.delegate = self
        return navigationBar
    }()

    let requiresFullScreen: Bool = true

    private let text: String
    private let appearance: LinkAppearance

    /// Closure called when a user confirms or cancels the declaration.
    var onResult: ((LinkController.CRSCARFDeclarationResult) -> Void)?

    /// Creates a new instance of `CRSCARFDeclarationContentViewController`.
    /// - Parameters:
    ///   - text: The declaration text to display.
    ///   - appearance: Determines the colors, corner radius, and height of the confirmation button.
    init(text: String, appearance: LinkAppearance) {
        self.text = text
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        return scrollView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headingLabel,
            declarationLabel,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: LinkUI.smallContentSpacing,
            leading: LinkUI.largeContentSpacing,
            bottom: LinkUI.largeContentSpacing,
            trailing: LinkUI.largeContentSpacing
        )
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = "Declarations"
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private lazy var declarationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 0
        label.attributedText = attributedDeclarationText
        return label
    }()

    private var attributedDeclarationText: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = LinkUI.smallContentSpacing / 2
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
            ]
        )
    }

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubviewToSafeArea(confirmButton, insets: .insets(amount: LinkUI.largeContentSpacing))
        return view
    }()

    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: "Agree and accept"),
        showProcessingLabel: false,
        linkAppearance: appearance
    ) { [weak self] in
        self?.confirmButtonTapped()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        view.addSubview(bottomButtonContainer)

        NSLayoutConstraint.activate([
            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor),
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
