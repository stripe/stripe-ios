//
//  LinkAccountPickerBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkAccountPickerBodyViewDelegate: AnyObject {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple
    )
    func linkAccountPickerBodyViewSelectedNewBankAccount(_ view: LinkAccountPickerBodyView)
}

final class LinkAccountPickerBodyView: UIView {

    weak var delegate: LinkAccountPickerBodyViewDelegate?
    private var partnerAccountIdToRowView: [String: AccountPickerRowView] = [:]

    init(
        accountTuples: [FinancialConnectionsAccountTuple],
        addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount,
        appearance: FinancialConnectionsAppearance
    ) {
        super.init(frame: .zero)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16

        // add account rows
        accountTuples.forEach { accountTuple in
            let accountRowView = AccountPickerRowView(
                isDisabled: !accountTuple.accountPickerAccount.allowSelection && accountTuple.accountPickerAccount.drawerOnSelection == nil,
                isFaded: !accountTuple.accountPickerAccount.allowSelection,
                appearance: appearance,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.linkAccountPickerBodyView(
                        self,
                        didSelectAccount: accountTuple
                    )
                }
            )
            let rowTitles = AccountPickerHelpers.rowInfo(
                forAccount: accountTuple.partnerAccount
            )
            accountRowView.set(
                institutionIconUrl: (accountTuple.accountPickerAccount.accountIcon?.default ?? accountTuple.partnerAccount.institution?.icon?.default ?? accountTuple.accountPickerAccount.icon?.default),
                title: rowTitles.accountName,
                subtitle: {
                    if let caption = accountTuple.accountPickerAccount.caption {
                        return caption
                    } else {
                        return rowTitles.accountNumbers
                    }
                }(),
                underlineSubtitle: accountTuple.accountPickerAccount.drawerOnSelection != nil,
                balanceString:
                    (accountTuple.accountPickerAccount.caption == nil) ? rowTitles.balanceString : nil,
                isSelected: false // initially nothing is selected
            )
            partnerAccountIdToRowView[accountTuple.partnerAccount.id] = accountRowView
            verticalStackView.addArrangedSubview(accountRowView)
        }

        // add a 'new bank account' button row
        let newAccountRowView = LinkAccountPickerNewAccountRowView(
            title: addNewAccount.body,
            imageUrl: addNewAccount.icon?.default,
            appearance: appearance,
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.linkAccountPickerBodyViewSelectedNewBankAccount(self)
            }
        )
        newAccountRowView.accessibilityIdentifier = "add_bank_account"
        verticalStackView.addArrangedSubview(newAccountRowView)

        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple]) {
        let selectedAccountIds = Set(selectedAccounts.map({ $0.partnerAccount.id }))
        partnerAccountIdToRowView
            .forEach { (partnerAccountId: String, rowView: AccountPickerRowView) in
                rowView.set(
                    isSelected: selectedAccountIds.contains(partnerAccountId)
                )
            }
    }
}

#if DEBUG

import SwiftUI

private struct LinkAccountPickerBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> LinkAccountPickerBodyView {
        LinkAccountPickerBodyView(
            accountTuples: [
                (
                    accountPickerAccount: FinancialConnectionsNetworkingAccountPicker.Account(
                        id: "123",
                        allowSelection: true,
                        caption: nil,
                        selectionCta: nil,
                        icon: nil,
                        selectionCtaIcon: nil,
                        drawerOnSelection: nil,
                        accountIcon: nil,
                        dataAccessNotice: nil
                    ),
                    partnerAccount: FinancialConnectionsPartnerAccount(
                        id: "abc",
                        name: "Advantage Plus Checking With Extra Words",
                        displayableAccountNumbers: "1324",
                        linkedAccountId: nil,
                        balanceAmount: 100000,
                        currency: "USD",
                        supportedPaymentMethodTypes: [.usBankAccount],
                        allowSelection: true,
                        allowSelectionMessage: nil,
                        status: "active",
                        institution: FinancialConnectionsInstitution(
                            id: "abc",
                            name: "N/A",
                            url: nil,
                            icon: FinancialConnectionsImage(
                                default: "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png"
                            ),
                            logo: nil
                        ),
                        nextPaneOnSelection: .success,
                        authorization: nil
                    )
                ),
                (
                    accountPickerAccount: FinancialConnectionsNetworkingAccountPicker.Account(
                        id: "123",
                        allowSelection: true,
                        caption: "Repair and connect account",
                        selectionCta: nil,
                        icon: FinancialConnectionsImage(
                            default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--warning-orange-3x.png"
                        ),
                        selectionCtaIcon: nil,
                        drawerOnSelection: nil,
                        accountIcon: nil,
                        dataAccessNotice: nil
                    ),
                    partnerAccount: FinancialConnectionsPartnerAccount(
                        id: "abc",
                        name: "Advantage Plus Checking",
                        displayableAccountNumbers: "1324",
                        linkedAccountId: nil,
                        balanceAmount: 100000,
                        currency: "USD",
                        supportedPaymentMethodTypes: [.usBankAccount],
                        allowSelection: true,
                        allowSelectionMessage: nil,
                        status: "disabled",
                        institution: nil,
                        nextPaneOnSelection: .success,
                        authorization: nil
                    )
                ),
                (
                    accountPickerAccount: FinancialConnectionsNetworkingAccountPicker.Account(
                        id: "123",
                        allowSelection: false,
                        caption: nil,
                        selectionCta: nil,
                        icon: nil,
                        selectionCtaIcon: nil,
                        drawerOnSelection: nil,
                        accountIcon: nil,
                        dataAccessNotice: nil
                    ),
                    partnerAccount: FinancialConnectionsPartnerAccount(
                        id: "abc",
                        name: "Advantage Plus Checking",
                        displayableAccountNumbers: "1324",
                        linkedAccountId: nil,
                        balanceAmount: 100000,
                        currency: "USD",
                        supportedPaymentMethodTypes: [.usBankAccount],
                        allowSelection: true,
                        allowSelectionMessage: nil,
                        status: "disabled",
                        institution: nil,
                        nextPaneOnSelection: .success,
                        authorization: nil
                    )
                ),
            ],
            addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount(
                body: "New bank account",
                icon: FinancialConnectionsImage(
                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png"
                )
            ),
            appearance: .stripe
        )
    }

    func updateUIView(_ uiView: LinkAccountPickerBodyView, context: Context) {
        uiView.selectAccounts([])
    }
}

struct LinkAccountPickerBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            LinkAccountPickerBodyViewUIViewRepresentable()
                .frame(maxHeight: 300)
                .padding()
            Spacer()
        }
    }
}

#endif
