//
//  VerifyKYCContentViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/30/25.
//

import UIKit

@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore

/// The content view of `VerifyKYCViewController`, which displays a list of KYC fields with the optional ability to initiate editing of the address.
final class VerifyKYCContentViewController: UIViewController, BottomSheetContentViewController {
    private enum Constants {
        static let layoutMargins = NSDirectionalEdgeInsets.insets(leading: 24, trailing: 24)
        static let ctaLayoutMargins = NSDirectionalEdgeInsets.insets(amount: 24)
        static let infoContainerCornerRadius: CGFloat = 12
    }

    // MARK: - BottomSheetContentViewController

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(isTestMode: false, appearance: .default)
        navigationBar.setStyle(.close(showAdditionalButton: false))
        navigationBar.delegate = self
        return navigationBar
    }()

    let requiresFullScreen: Bool = true

    // MARK: - VerifyKYCContentViewController

    private let info: KYCRefreshInfo
    private let appearance: LinkAppearance

    /// Closure called when a user takes action (confirm, cancel, or initiate editing of the address).
    var onResult: ((VerifyKycResult) -> Void)?

    /// Creates a new instance of `VerifyKYCContentViewController`.
    /// - Parameters:
    ///   - info: The KYC information to display.
    ///   - appearance: Determines the colors, corner radius, and height of the "Confirm" button.
    init(info: KYCRefreshInfo, appearance: LinkAppearance) {
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
            containerStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        return scrollView
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headingLabel,
            infoContainerView
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.layoutMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = "Confirm your information"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var infoContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.backgroundColor = .linkSurfaceSecondary
        container.layer.cornerRadius = Constants.infoContainerCornerRadius
        container.layer.masksToBounds = true

        let name = formattedName(first: info.firstName, last: info.lastName)
        let dob = formattedDOB(info.dateOfBirth)
        let last4 = info.idNumberLast4 ?? ""
        let address = formattedAddress(info.address)

        let stackView = UIStackView(arrangedSubviews: [
            KYCInfoRowView(title: "Name", value: name),
            makeDivider(),
            KYCInfoRowView(title: "Date of Birth", value: dob),
            makeDivider(),
            KYCInfoRowView(title: "Last 4 digits of SSN", value: last4),
            makeDivider(),
            KYCInfoRowView(title: "Address", value: address, editAction: { [weak self] in
                self?.onResult?(.updateAddress)
            })
        ])

        stackView.axis = .vertical

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

    private func formattedName(first: String, last: String?) -> String {
        let lastTrimmed = (last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return lastTrimmed.isEmpty ? first : "\(first) \(lastTrimmed)"
    }

    private func formattedDOB(_ dob: KycInfo.DateOfBirth) -> String {
        let mm = String(format: "%02d", dob.month)
        let dd = String(format: "%02d", dob.day)
        let yyyy = String(format: "%04d", dob.year)
        return "\(mm)/\(dd)/\(yyyy)"
    }

    private func formattedAddress(_ address: Address) -> String {
        [address.line1, address.line2, address.city, address.state, address.country, address.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private lazy var bottomButtonContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addAndPinSubviewToSafeArea(confirmButton, insets: Constants.ctaLayoutMargins)
        return view
    }()

    private lazy var confirmButton: ConfirmButton = .makeLinkButton(
        callToAction: .custom(title: "Confirm"),
        showProcessingLabel: false,
        linkAppearance: appearance
    ) { [weak self] in
        self?.onResult?(.confirmed)
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
            scrollView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor)
        ])
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}
