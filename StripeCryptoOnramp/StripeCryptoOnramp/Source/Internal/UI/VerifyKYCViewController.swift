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


final class KYCInfoRowView: UIView {
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
