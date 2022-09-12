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
    
    private let enabledAccounts: [FinancialConnectionsPartnerAccount]
    private let disabledAccounts: [FinancialConnectionsDisabledPartnerAccount]
    private var wrappedAccounts: [WrappedAccount] {
        return enabledAccounts.map { .enabled($0) } + disabledAccounts.map { .disabled($0) }
    }
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
    private var didSelectTheFirstAccountInAccountPickerView = false
    private var isSelectingAccounts: Bool = false {
        didSet {
            updateBorderColor()
        }
    }
    
    init(
        enabledAccounts: [FinancialConnectionsPartnerAccount],
        disabledAccounts: [FinancialConnectionsDisabledPartnerAccount],
        institution: FinancialConnectionsInstitution
    ) {
        self.enabledAccounts = enabledAccounts
        self.disabledAccounts = disabledAccounts
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
            institution: institution,
            wrappedAccount: wrappedAccounts.first
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
        
        let dropdownControlView: UIView
        if
            let selectedAccount = selectedAccounts.first,
            let wrappedSelectedAccount = wrappedAccounts.first(where: { $0.id == selectedAccount.id })
        {
            // show a "dropdown" control (with chevron) that shows a selected account
            dropdownControlView = CreateDropdownControlView(
                institution: institution,
                wrappedAccount: wrappedSelectedAccount
            )
        } else {
            // show a "dropdown" control (with chevron) that shows "choose one"
            dropdownControlView = CreateDropdownControlView()
        }
        containerView.addAndPinSubview(dropdownControlView)
        
        // Sync the `selectedAccounts` state with `UIPickerView` state.
        //
        // The code below is likely not necessary, but we add it
        // to ensure that `selectedAccounts` and `UIPickerView` is synced.
        if
            let selectedAccount = selectedAccounts.first,
            let selectedAccountIndex = wrappedAccounts.firstIndex(where: { $0.id == selectedAccount.id })
        {
            accountPickerView.selectRow(selectedAccountIndex, inComponent: 0, animated: false)
        }
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

// MARK: - UIPickerViewDelegate + UIPickerViewDataSource

extension AccountPickerSelectionDropdownView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return wrappedAccounts.count
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
        if !didSelectTheFirstAccountInAccountPickerView {
            didSelectTheFirstAccountInAccountPickerView = true
            DispatchQueue.main.async {
                let selectedRow = pickerView.selectedRow(inComponent: component)
                // UIPickerView does not call `pickerView:didSelectRow:inComponent:` the first
                // time its presented, so here we do that to sync `selectedAccounts` and UIPickerView
                self.pickerView(pickerView, didSelectRow: selectedRow, inComponent: component)
            }
        }
        
        let wrappedAccount = wrappedAccounts[row]
        let view = CreateAccountPickerRowView(institution: institution, wrappedAccount: wrappedAccount)
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let wrappedAccount = wrappedAccounts[row]
        switch wrappedAccount {
        case .enabled(let account):
            delegate?.accountPickerSelectionDropdownView(self, didSelectAccount: account)
        case .disabled(_):
            if
                let firstEnabledAccount = enabledAccounts.first,
                let firstEnabledAccountRow = wrappedAccounts.firstIndex(where: { $0.id == firstEnabledAccount.id })
            {
                // user selected a disabled account...scroll back to the first enabled account
                pickerView.selectRow(firstEnabledAccountRow, inComponent: component, animated: true)
                delegate?.accountPickerSelectionDropdownView(self, didSelectAccount: firstEnabledAccount)
            } else {
                // don't report a selected account because we couldn't find an enabled account
                assertionFailure("this should never get called unless we have no enabled accounts; API is expected to return an error at the account polling stage if there are no enabled accounts")
            }
        }
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

private enum WrappedAccount {
    case enabled(FinancialConnectionsPartnerAccount)
    case disabled(FinancialConnectionsDisabledPartnerAccount)
    
    var id: String {
        switch self {
        case .enabled(let account):
            return account.id
        case .disabled(let disabledAccount):
            return disabledAccount.account.id
        }
    }
}

private func CreateDropdownControlView(
    institution: FinancialConnectionsInstitution? = nil,
    wrappedAccount: WrappedAccount? = nil
) -> UIView {
    let labelView: UIView
    if let institution = institution, let wrappedAccount = wrappedAccount {
        let selectedAccountLabel = CreateInstitutionIconWithLabelView(
            institution: institution,
            wrappedAccount: wrappedAccount,
            hideSubtitle: true
        )
        labelView = selectedAccountLabel
    } else {
        let chooseOneLabel = UILabel()
        chooseOneLabel.textColor = .textSecondary
        chooseOneLabel.font = .stripeFont(forTextStyle: .body)
        chooseOneLabel.text = STPLocalizedString("Choose one", "The title of a button that allows users to open a user-interface that allows them to choose, and select, a single bank account. This button appears in a screen that allows users to select which bank accounts they want to use to pay for something.")
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
    wrappedAccount: WrappedAccount
) -> UIView {
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            CreateInstitutionIconWithLabelView(
                institution: institution,
                wrappedAccount: wrappedAccount,
                hideSubtitle: false // show subtitle in UIPickerView
            )
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    
    if case .disabled(_) = wrappedAccount {
        horizontalStackView.alpha = 0.25
    }
    
    return horizontalStackView
}

private func CreateInstitutionIconWithLabelView(
    institution: FinancialConnectionsInstitution,
    wrappedAccount: WrappedAccount,
    hideSubtitle: Bool
) -> UIView {
    let institutionIconImageView = UIImageView()
    institutionIconImageView.backgroundColor = .textDisabled // TODO(kgaidis): add icon
    institutionIconImageView.layer.cornerRadius = 6
    institutionIconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        institutionIconImageView.widthAnchor.constraint(equalToConstant: 24),
        institutionIconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    
    let labelRowView = AccountPickerLabelRowView()
    switch wrappedAccount {
    case .enabled(let account):
        let rowTitles = AccountPickerHelpers.rowTitles(forAccount: account)
        labelRowView.setLeadingTitle(
            rowTitles.leadingTitle,
            trailingTitle: hideSubtitle ? "••••\(account.displayableAccountNumbers ?? "")" : rowTitles.trailingTitle,
            subtitle: hideSubtitle ? nil : AccountPickerHelpers.rowSubtitle(forAccount: account),
            isLinked: account.linkedAccountId != nil
        )
    case .disabled(let disabledAccount):
        assert(!hideSubtitle, "hiding subtitle implies that we are showing a disabled account as a selected account which should never happen")
        labelRowView.setLeadingTitle(
            AccountPickerHelpers.rowTitles(forAccount: disabledAccount.account).leadingTitle,
            trailingTitle: "••••\(disabledAccount.account.displayableAccountNumbers ?? "")",
            subtitle: hideSubtitle ? nil : disabledAccount.disableReason,
            isLinked: false
        )
    }
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            institutionIconImageView,
            labelRowView,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    return horizontalStackView
}
