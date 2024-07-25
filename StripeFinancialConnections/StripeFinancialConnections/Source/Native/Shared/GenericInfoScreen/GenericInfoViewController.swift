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
    private let theme: FinancialConnectionsTheme
    private let didSelectPrimaryButton: (_ genericInfoViewController: GenericInfoViewController) -> Void
    private let didSelectSecondaryButton: (_ genericInfoViewController: GenericInfoViewController) -> Void
    private let didSelectURL: (URL) -> Void

    init(
        genericInfoScreen: FinancialConnectionsGenericInfoScreen,
        theme: FinancialConnectionsTheme,
        panePresentationStyle: PanePresentationStyle,
        didSelectPrimaryButton: @escaping (_ genericInfoViewController: GenericInfoViewController) -> Void,
        didSelectSecondaryButton: ((_ genericInfoViewController: GenericInfoViewController) -> Void)? = nil,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.genericInfoScreen = genericInfoScreen
        self.theme = theme
        self.didSelectPrimaryButton = didSelectPrimaryButton
        self.didSelectSecondaryButton = didSelectSecondaryButton ?? { _ in }
        self.didSelectURL = didSelectURL
        super.init(panePresentationStyle: panePresentationStyle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: {
                    if let imageUrl = genericInfoScreen.header?.icon?.default {
                        return RoundedIconView(
                            image: .imageUrl(imageUrl),
                            style: .circle,
                            theme: theme
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
                theme: theme,
                didSelectPrimaryButton: { [weak self] in
                    guard let self else { return }
                    didSelectPrimaryButton(self)
                },
                didSelectSecondaryButton: { [weak self] in
                    guard let self else { return }
                    didSelectSecondaryButton(self)
                },
                didSelectURL: didSelectURL
            )
        )
    }
}
