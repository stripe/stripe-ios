//
//  AccountPickerSelectionDropdownView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/19/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol AccountPickerSelectionDropdownViewDelegate: AnyObject {
    func accountPickerSelectionDropdownView(
        _ view: AccountPickerSelectionDropdownView,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    )
}

final class AccountPickerSelectionDropdownView: UIView {
    
    private let allAccounts: [FinancialConnectionsPartnerAccount]
    private let institution: FinancialConnectionsInstitution
    weak var delegate: AccountPickerSelectionDropdownViewDelegate?
    
    // `UITextField` is used to show a `UIPickerView` keyboard
    private lazy var invisibleTextField: UITextField = {
        return UITextField()
    }()
    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .customBackgroundColor
        return containerView
    }()
    private lazy var accountPickerView: UIPickerView = {
        let accountPickerView = UIPickerView()
        accountPickerView.delegate = self
        accountPickerView.dataSource = self
        accountPickerView.backgroundColor = .customBackgroundColor
        return accountPickerView
    }()
    private var isSelectingAccounts: Bool = false {
        didSet {
            updateBorderColor()
        }
    }
    
    init(
        allAccounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution
    ) {
        self.allAccounts = allAccounts
        self.institution = institution
        super.init(frame: .zero)
        layer.cornerRadius = 8
        updateBorderColor()
        
        // track whether user presses the view
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapView)
        )
        addGestureRecognizer(tapGestureRecognizer)
        
        setupInvisibleTextField()
        addAndPinSubview(invisibleTextField)
        
        // The `invisibleResizingView` ensures that the "dropdown control"
        // is always sized correctly.
        //
        // The "no account selected" state is smaller than
        // the "account selected" state so we create a 'fake'
        // "account selected" view to control the sizing.
        //
        // This is especially important for dynamic type support.
        let invisibleResizingView = CreateDropdownControlView(
            // this should never be visible, but we
            // add reasonable text anyway to:
            // 1. ensure correct sizing is done (as-if there was text)
            // 2. in case this is shown due to a bug, we show ~decent text
            selectedAccountName: "Choose One Account",
            institution: institution
        )
        addAndPinSubview(invisibleResizingView)
        invisibleResizingView.addAndPinSubview(containerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupInvisibleTextField() {
        // create a "account keyboard" for when user selects the text field
        invisibleTextField.inputView = accountPickerView
        
        // create a "keyboard toolbar" for when user selects the text field
        invisibleTextField.inputAccessoryView = CreateKeyboardToolbar(self)
        
        invisibleTextField.delegate = self
    }
    
    private func updateBorderColor() {
        if isSelectingAccounts {
            layer.borderColor = UIColor.textBrand.cgColor
            layer.borderWidth = 2.0
        } else {
            layer.borderColor = UIColor.borderNeutral.cgColor
            layer.borderWidth = 1.0 / UIScreen.main.nativeScale
        }
    }
    
    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        // clear previous state
        containerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        // show either:
        // 1. a "dropdown" control (with chevron) that shows "choose one"
        // 2. a "dropdown" control (with chevron) that shows a selected account
        let dropdownControlView: UIView
        if let selectedAccount = selectedAccounts.first {
            dropdownControlView = CreateDropdownControlView(
                selectedAccountName: selectedAccount.name,
                displayableAccountNumbers: selectedAccount.displayableAccountNumbers,
                institution: institution
            )
        } else {
            dropdownControlView = CreateDropdownControlView()
        }
        containerView.addAndPinSubview(dropdownControlView)
    }
    
    @objc fileprivate func didSelectDone() {
        invisibleTextField.resignFirstResponder()
    }
    
    @objc private func didTapView() {
        if invisibleTextField.isFirstResponder {
            invisibleTextField.resignFirstResponder()
        } else {
            invisibleTextField.becomeFirstResponder()
        }
    }
}

// MARK: - ...

extension AccountPickerSelectionDropdownView: UIPickerViewDelegate, UIPickerViewDataSource {
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allAccounts.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 70 // TODO(kgaidis): automatically size UIPickerView...
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let account = allAccounts[row]
        let view = CreateAccountPickerRowView(institution: institution, account: account)
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.accountPickerSelectionDropdownView(self, didSelectAccount: allAccounts[row])
    }
}

// MARK: - UITextFieldDelegate

extension AccountPickerSelectionDropdownView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isSelectingAccounts = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        isSelectingAccounts = false
    }
}

// MARK: - Helpers

private func CreateDropdownControlView(
    selectedAccountName: String? = nil,
    displayableAccountNumbers: String? = nil,
    institution: FinancialConnectionsInstitution? = nil
) -> UIView {
    let labelView: UIView
    if let selectedAccountName = selectedAccountName, let institution = institution {
        let selectedAccountLabel = CreateInstitutionIconWithLabelView(
            instituion: institution,
            text: {
                if let displayableAccountNumbers = displayableAccountNumbers {
                    return "\(selectedAccountName) ••••\(displayableAccountNumbers)"
                } else {
                    return selectedAccountName
                }
            }()
        )
        labelView = selectedAccountLabel
    } else {
        let chooseOneLabel = UILabel()
        chooseOneLabel.textColor = .textSecondary
        chooseOneLabel.font = .stripeFont(forTextStyle: .body)
        chooseOneLabel.text = "Choose one"
        labelView = chooseOneLabel
    }
    labelView.translatesAutoresizingMaskIntoConstraints = false
    labelView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    labelView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            labelView,
            CreateChevronView(),
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    horizontalStackView.distribution = .fillProportionally
    return horizontalStackView
}

private func CreateChevronView() -> UIView {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    if #available(iOS 13.0, *) {
        imageView.image = UIImage(systemName: "chevron.down")?.withTintColor(.textDisabled, renderingMode: .alwaysOriginal)
    } else {
        assertionFailure()
    }
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 20),
    ])
    return imageView
}

private func CreateKeyboardToolbar(_ view: AccountPickerSelectionDropdownView) -> UIView {
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
    toolbar.clipsToBounds = true // removes border created by iOS
    toolbar.tintColor = .textBrand
    toolbar.barTintColor = .backgroundContainer // background color
    toolbar.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
    toolbar.layer.borderColor = UIColor.borderNeutral.cgColor
    
    let doneButton = UIBarButtonItem(
        barButtonSystemItem: .done,
        target: view,
        action: #selector(AccountPickerSelectionDropdownView.didSelectDone)
    )
    doneButton.setTitleTextAttributes([
        .font: UIFont.stripeFont(forTextStyle: .bodyEmphasized),
    ], for: .normal)
    toolbar.setItems([.flexibleSpace(), doneButton], animated: false)
    
    return toolbar
}

private func CreateAccountPickerRowView(
    institution: FinancialConnectionsInstitution,
    account: FinancialConnectionsPartnerAccount
) -> UIView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    
    horizontalStackView.addArrangedSubview(
        CreateInstitutionIconWithLabelView(
            instituion: institution,
            text: {
                if let displayableAccountNumbers = account.displayableAccountNumbers {
                    return "\(account.name) ••••\(displayableAccountNumbers)"
                } else {
                    return account.name
                }
            }()
        )
    )
    
    return horizontalStackView
}

private func CreateInstitutionIconWithLabelView(instituion: FinancialConnectionsInstitution, text: String) -> UIView {
    let institutionIconImageView = UIImageView()
    institutionIconImageView.backgroundColor = .textDisabled // TODO(kgaidis): add icon
    institutionIconImageView.layer.cornerRadius = 6
    institutionIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        institutionIconImageView.widthAnchor.constraint(equalToConstant: 24),
        institutionIconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    
    let institutionLabel = UILabel()
    institutionLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
    institutionLabel.textColor = .textPrimary
    institutionLabel.text = text
    institutionLabel.translatesAutoresizingMaskIntoConstraints = false
    institutionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            institutionIconImageView,
            institutionLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    return horizontalStackView
}
