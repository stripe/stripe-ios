//
//  AccountUpdateRequiredViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 3/26/24.
//

import Foundation
import UIKit

final class AccountUpdateRequiredViewController: SheetViewController {

    private let institution: FinancialConnectionsInstitution?
    private let didSelectContinue: () -> Void
    private let didSelectCancel: () -> Void
    private let willDismissSheet: () -> Void

    init(
        institution: FinancialConnectionsInstitution?,
        didSelectContinue: @escaping () -> Void,
        didSelectCancel: @escaping () -> Void,
        willDismissSheet: @escaping () -> Void
    ) {
        self.institution = institution
        self.didSelectContinue = didSelectContinue
        self.didSelectCancel = didSelectCancel
        self.willDismissSheet = willDismissSheet
        super.init(panePresentationStyle: .sheet)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institution?.icon?.default)
                    return institutionIconView
                }(),
                title: STPLocalizedString(
                    "Update required",
                    "The title of a screen that allows users to choose whether they want to proceed to update their bank accocunt."
                ),
                subtitle: STPLocalizedString(
                    "Next, you'll be prompted to log in and connect your accounts.",
                    "The subtitle of a screen that allows users to choose whether they want to proceed to update their bank accocunt."
                ),
                contentView: nil,
                isSheet: true
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: "Continue", // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.continue`
                    accessibilityIdentifier: "account_update_required_continue_button",
                    action: didSelectContinue
                ),
                secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: "Cancel", // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.cancel`
                    action: didSelectCancel
                )
            ).footerView
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            willDismissSheet()
        }
    }
}
