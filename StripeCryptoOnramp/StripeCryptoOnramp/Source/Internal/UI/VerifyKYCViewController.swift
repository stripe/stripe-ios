//
//  VerifyKYCViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/28/25.
//

import UIKit
import SwiftUI

@_spi(STP) import StripeUICore
@_spi(STP) import StripePaymentSheet

final class VerifyKYCViewController: BottomSheetViewController {
    private enum Constants {
        static let sheetCornerRadius: CGFloat = 24
    }

    private weak var contentViewController: VerifyKYCContentViewController?

    var onResult: ((VerifyKycResult) -> Void)? {
        didSet {
            contentViewController?.onResult = onResult
        }
    }

    override var sheetCornerRadius: CGFloat? {
        Constants.sheetCornerRadius
    }

    init(info: KYCRefreshInfo, appearance: LinkAppearance) {
        let contentViewController = VerifyKYCContentViewController(info: info, appearance: appearance)
        self.contentViewController = contentViewController

        super.init(
            contentViewController: contentViewController,
            appearance: LinkUI.appearance,
            isTestMode: false,
            didCancelNative3DS2: {}
        )

        appearance.style.configure(self)
    }

    override func didTapOrSwipeToDismiss() {
        contentViewController?.didTapOrSwipeToDismiss()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(contentViewController: any BottomSheetContentViewController, appearance: PaymentSheet.Appearance, isTestMode: Bool, didCancelNative3DS2: @escaping () -> Void) {
        fatalError("init(contentViewController:appearance:isTestMode:didCancelNative3DS2:) has not been implemented")
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

    var onResult: ((VerifyKycResult) -> Void)?

    init(info: KYCRefreshInfo, appearance: LinkAppearance) {
        self.info = info
        self.appearance = appearance
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
        label.text = "Confirm your information"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headingLabel,
            kycInfoContainerView
        ])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = Constants.layoutMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var kycInfoContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.backgroundColor = .linkSurfaceSecondary
        container.layer.cornerRadius = Constants.infoContainerCornerRadius
        container.layer.masksToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false

        let name = formattedName(first: info.firstName, last: info.lastName)
        let dob = formattedDOB(info.dateOfBirth)
        let last4 = info.idNumberLast4 ?? ""
        let address = formattedAddress(info.address)

        let rows: [UIView] = [
            KYCInfoRowView(title: "Name", value: name),
            KYCInfoRowView(title: "Date of Birth", value: dob),
            KYCInfoRowView(title: "Last 4 digits of SSN", value: last4),
            KYCInfoRowView(title: "Address", value: address, editAction: { [weak self] in
                self?.onResult?(.updateAddress)
            })
        ]

        for (idx, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            if idx < rows.count - 1 {
                stack.addArrangedSubview(makeDivider())
            }
        }

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

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
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
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

        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        view.addSubview(bottomButtonContainer)

        bottomButtonContainer.addAndPinSubviewToSafeArea(confirmButton, insets: Constants.ctaLayoutMargins)

        NSLayoutConstraint.activate([
            bottomButtonContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bottomButtonContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomButtonContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomButtonContainer.topAnchor)
        ])

        scrollView.addSubview(containerStackView)
        NSLayoutConstraint.activate([
            containerStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - BottomSheetContentViewController

    func didTapOrSwipeToDismiss() {
        onResult?(.canceled)
    }
}

// MARK: - Private Views

private final class KYCInfoRowView: UIView {
    private enum Constants {
        static let editButtonSize = CGSize(width: 44, height: 44)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .linkTextTertiary
        label.numberOfLines = 0
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = LinkUI.font(forTextStyle: .body)
        label.textColor = .linkTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setImage(Image.kycVerifyEdit.makeImage(), for: .normal)
        button.tintColor = .linkIconPrimary
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Constants.editButtonSize.width),
            button.heightAnchor.constraint(equalToConstant: Constants.editButtonSize.height),
        ])
        return button
    }()

    private var editAction: (() -> Void)?

    init(title: String, value: String, editAction: (() -> Void)? = nil) {
        self.editAction = editAction

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        valueLabel.text = value

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .vertical

        let rowStack = UIStackView(arrangedSubviews: [labelsStack])
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.alignment = .center
        rowStack.spacing = LinkUI.contentSpacing

        var insets = NSDirectionalEdgeInsets.insets(amount: LinkUI.contentSpacing)

        if editAction != nil {
            editButton.addTarget(self, action: #selector(didTapEdit), for: .touchUpInside)
            rowStack.addArrangedSubview(editButton)
            insets.trailing = 0
        }

        addAndPinSubview(rowStack, insets: insets)
    }

    @objc private func didTapEdit() {
        editAction?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
