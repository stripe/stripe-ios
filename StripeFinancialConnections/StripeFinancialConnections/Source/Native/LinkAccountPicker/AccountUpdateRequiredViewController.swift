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
                title: "Update required", // TODO: localize
                subtitle: "Next, you'll be prompted to log in and connect your accounts.",  // TODO: localize
                contentView: nil,
                isSheet: true
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: "Continue",  // TODO: localize
                    action: didSelectContinue
                ),
                secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: "Cancel",  // TODO: localize
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
