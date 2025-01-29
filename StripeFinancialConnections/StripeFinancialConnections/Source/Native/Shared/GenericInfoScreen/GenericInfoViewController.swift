//
//  GenericInfoViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/2/24.
//

import Foundation
import UIKit

final class GenericInfoViewController: SheetViewController {

    private let genericInfoScreen: FinancialConnectionsGenericInfoScreen
    private let appearance: FinancialConnectionsAppearance
    private let iconView: UIView?
    private let didSelectPrimaryButton: (_ genericInfoViewController: GenericInfoViewController) -> Void
    private let didSelectSecondaryButton: ((_ genericInfoViewController: GenericInfoViewController) -> Void)?
    private let didSelectURL: (URL) -> Void
    private let willDismissSheet: (() -> Void)?

    init(
        genericInfoScreen: FinancialConnectionsGenericInfoScreen,
        appearance: FinancialConnectionsAppearance,
        panePresentationStyle: PanePresentationStyle,
        iconView: UIView? = nil,
        didSelectPrimaryButton: @escaping (_ genericInfoViewController: GenericInfoViewController) -> Void,
        didSelectSecondaryButton: ((_ genericInfoViewController: GenericInfoViewController) -> Void)? = nil,
        didSelectURL: @escaping (URL) -> Void,
        willDismissSheet: (() -> Void)? = nil
    ) {
        self.genericInfoScreen = genericInfoScreen
        self.appearance = appearance
        self.iconView = iconView
        self.didSelectPrimaryButton = didSelectPrimaryButton
        self.didSelectSecondaryButton = didSelectSecondaryButton
        self.didSelectURL = didSelectURL
        self.willDismissSheet = willDismissSheet
        super.init(panePresentationStyle: panePresentationStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: iconView ?? {
                    if let imageUrl = genericInfoScreen.header?.icon?.default {
                        return RoundedIconView(
                            image: .imageUrl(imageUrl),
                            style: .circle,
                            appearance: appearance
                        )
                    } else {
                        return nil
                    }
                }(),
                title: genericInfoScreen.header?.title,
                subtitle: genericInfoScreen.header?.subtitle,
                headerAlignment: {
                    let headerAlignment = genericInfoScreen.header?.alignment
                    switch headerAlignment {
                    case .center:
                        return .center
                    case .right:
                        return .trailing
                    case .left: fallthrough
                    case .unparsable: fallthrough
                    case .none:
                        return .leading
                    }
                }(),
                contentView: GenericInfoBodyView(
                    body: genericInfoScreen.body,
                    didSelectURL: didSelectURL
                ),
                isSheet: (panePresentationStyle == .sheet)
            ),
            footerView: GenericInfoFooterView(
                footer: genericInfoScreen.footer,
                appearance: appearance,
                didSelectPrimaryButton: { [weak self] in
                    guard let self else { return }
                    didSelectPrimaryButton(self)
                },
                didSelectSecondaryButton: {
                    if let didSelectSecondaryButton {
                        return { [weak self] in
                            guard let self else { return }
                            didSelectSecondaryButton(self)
                        }
                    } else {
                        return nil
                    }
                }(),
                didSelectURL: didSelectURL
            )
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed, let willDismissSheet {
            willDismissSheet()
        }
    }
}
