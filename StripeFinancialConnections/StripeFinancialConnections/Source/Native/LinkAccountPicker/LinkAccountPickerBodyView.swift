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

    private let accountTuples: [FinancialConnectionsAccountTuple]
    private let addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount
    weak var delegate: LinkAccountPickerBodyViewDelegate?

    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        return verticalStackView
    }()

    init(
        accountTuples: [FinancialConnectionsAccountTuple],
        addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount
    ) {
        self.accountTuples = accountTuples
        self.addNewAccount = addNewAccount
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectAccount(_ selectedAccountTuple: FinancialConnectionsAccountTuple?) {
        // clear all previous state
        verticalStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        accountTuples.forEach { accountTuple in
            let accountRowView = LinkAccountPickerRowView(
                isDisabled: !accountTuple.accountPickerAccount.allowSelection,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.linkAccountPickerBodyView(
                        self,
                        didSelectAccount: accountTuple
                    )
                }
            )
            let rowTitles = AccountPickerHelpers.rowTitles(
                forAccount: accountTuple.partnerAccount,
                captionWillHideAccountNumbers: accountTuple.accountPickerAccount.caption != nil
            )
            accountRowView.configure(
                institutionImageUrl: accountTuple.partnerAccount.institution?.icon?.default,
                leadingTitle: rowTitles.leadingTitle,
                trailingTitle: rowTitles.trailingTitle,
                subtitle: {
                    if let caption = accountTuple.accountPickerAccount.caption {
                        return caption
                    } else {
                        return AccountPickerHelpers.rowSubtitle(
                            forAccount: accountTuple.partnerAccount
                        )
                    }
                }(),
                trailingIconImageUrl: accountTuple.accountPickerAccount.icon?.default,
                isSelected: selectedAccountTuple?.partnerAccount.id == accountTuple.partnerAccount.id
            )
            verticalStackView.addArrangedSubview(accountRowView)
        }

        // add a 'new bank account' button row
        let newAccountRowView = LinkAccountPickerNewAccountRowView(
            title: addNewAccount.body,
            imageUrl: addNewAccount.icon?.default,
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.linkAccountPickerBodyViewSelectedNewBankAccount(self)
            }
        )
        verticalStackView.addArrangedSubview(newAccountRowView)
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
                        selectionCtaIcon: nil
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
                        nextPaneOnSelection: .success
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
                        selectionCtaIcon: nil
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
                        nextPaneOnSelection: .success
                    )
                ),
                (
                    accountPickerAccount: FinancialConnectionsNetworkingAccountPicker.Account(
                        id: "123",
                        allowSelection: false,
                        caption: nil,
                        selectionCta: nil,
                        icon: nil,
                        selectionCtaIcon: nil
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
                        nextPaneOnSelection: .success
                    )
                ),
            ],
            addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount(
                body: "New bank account",
                icon: FinancialConnectionsImage(
                    default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--add-purple-3x.png"
                )
            )
        )
    }

    func updateUIView(_ uiView: LinkAccountPickerBodyView, context: Context) {
        uiView.selectAccount(nil)
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
