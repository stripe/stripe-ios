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
    
    private lazy var dropdownControlView: UIStackView = {
        let dropdownControlView = UIStackView()
        dropdownControlView.axis = .horizontal
        dropdownControlView.alignment = .center
        dropdownControlView.isLayoutMarginsRelativeArrangement = true
        dropdownControlView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        dropdownControlView.layer.cornerRadius = 8
        dropdownControlView.distribution = .fillProportionally
        return dropdownControlView
    }()
    
    private lazy var invisibleTextField: InvisibleTextField = {
        return InvisibleTextField()
    }()
    
    private var isSelectingAccounts: Bool = false {
        didSet {
            updateDropdownControlViewBorderColor()
        }
    }
    
    init(
        allAccounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution
    ) {
        self.allAccounts = allAccounts
        self.institution = institution
        super.init(frame: .zero)
        
        addAndPinSubview(invisibleTextField)
        
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.backgroundColor = .customBackgroundColor
        
        invisibleTextField.inputView = pickerView
        invisibleTextField.delegate = self
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        toolbar.clipsToBounds = true // removes border created by iOS
        toolbar.tintColor = .textBrand
        toolbar.barTintColor = .backgroundContainer // background color
        toolbar.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
        toolbar.layer.borderColor = UIColor.borderNeutral.cgColor
        
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didSelectDone)
        )
        doneButton.setTitleTextAttributes([
            .font: UIFont.stripeFont(forTextStyle: .bodyEmphasized),
        ], for: .normal)
        toolbar.setItems([.flexibleSpace(), doneButton], animated: false)
        
        invisibleTextField.inputAccessoryView = toolbar
        
        addAndPinSubview(dropdownControlView)
        
        updateDropdownControlViewBorderColor()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectDropdownControl))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateDropdownControlViewBorderColor() {
        if isSelectingAccounts {
            dropdownControlView.layer.borderColor = UIColor.textBrand.cgColor
            dropdownControlView.layer.borderWidth = 2.0
        } else {
            dropdownControlView.layer.borderColor = UIColor.borderNeutral.cgColor
            dropdownControlView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
        }
    }
    
    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        
        // clear state
        dropdownControlView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        if let selectedAccount = selectedAccounts.first {
            let accountLabel = CreateIconWithLabelView(instituion: institution, text: {
                if let displayableAccountNumbers = selectedAccount.displayableAccountNumbers {
                    return "\(selectedAccount.name) ••••\(displayableAccountNumbers)"
                } else {
                    return selectedAccount.name
                }
            }())
            accountLabel.translatesAutoresizingMaskIntoConstraints = false
            accountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            accountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
            dropdownControlView.addArrangedSubview(accountLabel)
        } else {
            let chooseOneLabel = UILabel()
            chooseOneLabel.textColor = .textSecondary
            chooseOneLabel.font = .stripeFont(forTextStyle: .body)
            chooseOneLabel.translatesAutoresizingMaskIntoConstraints = false
            chooseOneLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            chooseOneLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            chooseOneLabel.text = "Choose one"
            
            dropdownControlView.addArrangedSubview(chooseOneLabel)
        }
        
        dropdownControlView.addArrangedSubview(CreateChevronDown())
    }
    
    @objc private func didSelectDone() {
        invisibleTextField.resignFirstResponder()
    }
    
    @objc private func didSelectDropdownControl() {
        if invisibleTextField.isFirstResponder {
            invisibleTextField.resignFirstResponder()
        } else {
            
            invisibleTextField.becomeFirstResponder()
        }
    }
}

// MARK: - ...

extension AccountPickerSelectionDropdownView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.accountPickerSelectionDropdownView(self, didSelectAccount: allAccounts[row])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allAccounts.count
    }
    
    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let account = allAccounts[row]
        let view = CreateAccountRowView(institution: institution, account: account)
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 70
    }
}


extension AccountPickerSelectionDropdownView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        invisibleTextField.resignFirstResponder()
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


private func CreateChevronDown() -> UIView {
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
    return imageView
}

private func CreateAccountRowView(institution: FinancialConnectionsInstitution, account: FinancialConnectionsPartnerAccount) -> UIView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

    horizontalStackView.addArrangedSubview(
        CreateIconWithLabelView(
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

private func CreateIconWithLabelView(instituion: FinancialConnectionsInstitution, text: String) -> UIView {
    let institutionIconImageView = CreateInstitutionIconView()
    
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

private func CreateInstitutionIconView() -> UIView {
    let institutionIconImageView = UIImageView()
    institutionIconImageView.backgroundColor = .textDisabled // TODO(kgaidis): add icon
    institutionIconImageView.layer.cornerRadius = 6
    institutionIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        institutionIconImageView.widthAnchor.constraint(equalToConstant: 24),
        institutionIconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    return institutionIconImageView
}

private class InvisibleTextField: UITextField {

    init() {
        super.init(frame: .zero)
        
        // Prevents selection from flashing if the user double-taps on a word
        tintColor = .clear

        // Prevents text from being highlighted red if the user double-taps a word the spell checker doesn't recognize
        autocorrectionType = .no
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        // hide the caret
        return .zero
    }
}
