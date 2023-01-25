//
//  InformationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

/// A reusable view that allows developers to quickly
/// render information.
final class ReusableInformationView: UIView {

    enum IconType {
        case view(UIView)
        case loading
    }

    struct ButtonConfiguration {
        let title: String
        let action: () -> Void
    }

    private let primaryButtonAction: (() -> Void)?
    private let secondaryButtonAction: (() -> Void)?

    init(
        iconType: IconType,
        title: String,
        subtitle: String,
        // the primary button is the bottom-most button
        primaryButtonConfiguration: ButtonConfiguration? = nil,
        secondaryButtonConfiguration: ButtonConfiguration? = nil
    ) {
        self.primaryButtonAction = primaryButtonConfiguration?.action
        self.secondaryButtonAction = secondaryButtonConfiguration?.action
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        let paneLayoutView = PaneWithHeaderLayoutView(
            icon: .view(CreateIconView(iconType: iconType)),
            title: title,
            subtitle: subtitle,
            contentView: UIView(),
            footerView: CreateFooterView(
                primaryButtonConfiguration: primaryButtonConfiguration,
                secondaryButtonConfiguration: secondaryButtonConfiguration,
                view: self
            )
        )
        paneLayoutView.addTo(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func didSelectPrimaryButton() {
        primaryButtonAction?()
    }

    @objc fileprivate func didSelectSecondaryButton() {
        secondaryButtonAction?()
    }
}

private func CreateIconView(iconType: ReusableInformationView.IconType) -> UIView {

    switch iconType {
    case .view(let iconView):
        return iconView
    case .loading:
        return SpinnerIconView()
    }
}

private func CreateFooterView(
    primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?,
    secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?,
    view: ReusableInformationView
) -> UIView? {
    guard
        primaryButtonConfiguration != nil || secondaryButtonConfiguration != nil
    else {
        return nil  // display no footer
    }
    let footerStackView = UIStackView()
    footerStackView.axis = .vertical
    footerStackView.spacing = 12
    if let secondaryButtonConfiguration = secondaryButtonConfiguration {
        let secondaryButton = Button(configuration: .financialConnectionsSecondary)
        secondaryButton.title = secondaryButtonConfiguration.title
        secondaryButton.addTarget(
            view,
            action: #selector(ReusableInformationView.didSelectSecondaryButton),
            for: .touchUpInside
        )
        secondaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secondaryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        footerStackView.addArrangedSubview(secondaryButton)
    }
    if let primaryButtonConfiguration = primaryButtonConfiguration {
        let primaryButton = Button(configuration: .financialConnectionsPrimary)
        primaryButton.title = primaryButtonConfiguration.title
        primaryButton.addTarget(
            view,
            action: #selector(ReusableInformationView.didSelectPrimaryButton),
            for: .touchUpInside
        )
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            primaryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        footerStackView.addArrangedSubview(primaryButton)
    }
    return footerStackView
}

#if DEBUG

import SwiftUI

private struct ReusableInformationViewUIViewRepresentable: UIViewRepresentable {

    let primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?
    let secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?

    func makeUIView(context: Context) -> ReusableInformationView {
        ReusableInformationView(
            iconType: .loading,
            title: "Establishing connection",
            subtitle: "Please wait while a connection is established.",
            primaryButtonConfiguration: primaryButtonConfiguration,
            secondaryButtonConfiguration: secondaryButtonConfiguration
        )
    }

    func updateUIView(_ uiView: ReusableInformationView, context: Context) {}
}

struct ReusableInformationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ReusableInformationViewUIViewRepresentable(
                primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                    title: "Try Again",
                    action: {}
                ),
                secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                    title: "Enter Bank Details Manually",
                    action: {}
                )
            )
            .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))

        VStack {
            ReusableInformationViewUIViewRepresentable(
                primaryButtonConfiguration: nil,
                secondaryButtonConfiguration: nil
            )
            .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#endif
