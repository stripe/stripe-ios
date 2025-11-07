//
//  VerifyKYCContentViewController.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 10/30/25.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// The content view of `VerifyKYCViewController`, which displays a list of KYC fields with the optional ability to initiate editing of the address.
final class VerifyKYCContentViewController: UIViewController, BottomSheetContentViewController {

    // MARK: - BottomSheetContentViewController

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

    // MARK: - VerifyKYCContentViewController

    private let info: VerifyKYCInfo
    private let appearance: LinkAppearance

    /// Closure called when a user takes action (confirm, cancel, or initiate editing of the address).
    var onResult: ((VerifyKYCResult) -> Void)?

    /// Creates a new instance of `VerifyKYCContentViewController`.
    /// - Parameters:
    ///   - info: The KYC information to display.
    ///   - appearance: Determines the colors, corner radius, and height of the "Confirm" button.
    init(info: VerifyKYCInfo, appearance: LinkAppearance) {
        self.info = info
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
            infoContainerView,
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .insets(leading: LinkUI.largeContentSpacing, trailing: LinkUI.largeContentSpacing)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = String.Localized.confirm_your_information
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private var formattedName: String {
        var components = PersonNameComponents()
        components.givenName = info.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        components.familyName = info.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return PersonNameComponentsFormatter.localizedString(from: components, style: .default)
    }

    private var formattedDateOfBirth: String {
        // Format the date in a locale-friendly manner where components can change order
        // and use leading 0s for days and months < 10, e.g. 09/01/2000.
        var components = DateComponents()
        components.calendar = .current
        components.timeZone = .current
        components.year = info.dateOfBirthYear
        components.month = info.dateOfBirthMonth
        components.day = info.dateOfBirthDay

        if let date = components.date {
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.calendar = .current
            formatter.timeZone = .current
            formatter.setLocalizedDateFormatFromTemplate("MMddyyyy")
            return formatter.string(from: date)
        } else {
            // fall back to strict manual formatting in the event of an unexpected error with `DateComponents`.
            let mm = String(format: "%02d", info.dateOfBirthMonth)
            let dd = String(format: "%02d", info.dateOfBirthDay)
            let yyyy = String(format: "%04d", info.dateOfBirthYear)
            return "\(mm)/\(dd)/\(yyyy)"
        }
    }

    private var formattedAddress: String {
        [info.line1, info.line2, info.city, info.state, info.country, info.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private lazy var infoContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.backgroundColor = .linkSurfaceSecondary
        container.layer.cornerRadius = LinkUI.cornerRadius
        container.layer.masksToBounds = true

        let stackView = UIStackView()
        stackView.axis = .vertical

        stackView.addArrangedSubview(VerifyKYCInfoRowView(title: String.Localized.name, value: formattedName))
        stackView.addArrangedSubview(makeDivider())
        stackView.addArrangedSubview(VerifyKYCInfoRowView(title: String.Localized.date_of_birth, value: formattedDateOfBirth))
        stackView.addArrangedSubview(makeDivider())
        if let idNumberLast4 = info.idNumberLast4, !idNumberLast4.isEmpty {
            stackView.addArrangedSubview(VerifyKYCInfoRowView(title: String.Localized.last_4_digits_of_ssn, value: idNumberLast4))
            stackView.addArrangedSubview(makeDivider())
        }
        stackView.addArrangedSubview(VerifyKYCInfoRowView(title: String.Localized.address, value: formattedAddress, editAction: { [weak self] in
            self?.onResult?(.updateAddress)
        }))

        container.addAndPinSubview(stackView)

        return container
    }()

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .linkBorderDefault
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
        return divider
    }

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubviewToSafeArea(confirmButton, insets: .insets(amount: LinkUI.largeContentSpacing))
        return view
    }()

    private lazy var confirmButton = ConfirmButton.makeLinkButton(
        callToAction: .custom(title: String.Localized.confirm),
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
       confirmButton.update(state: .spinnerWithInteractionDisabled)
       onResult?(.confirmed)
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}
