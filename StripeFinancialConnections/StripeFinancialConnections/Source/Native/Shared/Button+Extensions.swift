//
//  Button+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/30/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

extension StripeUICore.Button {
    static func primary(theme: FinancialConnectionsTheme) -> StripeUICore.Button {
        let button = Button(configuration: .financialConnectionsPrimary(theme: theme))
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 5 / UIScreen.main.nativeScale
        button.layer.shadowOpacity = 0.25
        button.layer.shadowOffset = CGSize(
            width: 0,
            height: 2 / UIScreen.main.nativeScale
        )
        ButtonFeedbackGeneratorHandler.attach(toButton: button)
        return button
    }

    static func secondary() -> StripeUICore.Button {
        let button = Button(configuration: .financialConnectionsSecondary)
        ButtonFeedbackGeneratorHandler.attach(toButton: button)
        return button
    }
}

extension StripeUICore.Button.Configuration {

    fileprivate static func financialConnectionsPrimary(theme: FinancialConnectionsTheme) -> StripeUICore.Button.Configuration {
        var primaryButtonConfiguration = Button.Configuration.primary()
        primaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        primaryButtonConfiguration.cornerRadius = 12.0
        // default
        primaryButtonConfiguration.backgroundColor = theme.primaryColor
        primaryButtonConfiguration.foregroundColor = theme.primaryAccentColor
        // disabled
        primaryButtonConfiguration.disabledBackgroundColor = theme.primaryColor
        primaryButtonConfiguration.disabledForegroundColor = theme.primaryAccentColor.withAlphaComponent(0.4)
        // pressed
        primaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.23)  // this tries to simulate `brand600`
        primaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return primaryButtonConfiguration
    }

    fileprivate static var financialConnectionsSecondary: StripeUICore.Button.Configuration {
        var secondaryButtonConfiguration = Button.Configuration.secondary()
        secondaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        secondaryButtonConfiguration.cornerRadius = 12.0
        // default
        secondaryButtonConfiguration.foregroundColor = .textDefault
        secondaryButtonConfiguration.backgroundColor = .neutral25
        // disabled
        secondaryButtonConfiguration.disabledForegroundColor = .textDefault.withAlphaComponent(0.4)
        secondaryButtonConfiguration.disabledBackgroundColor = .neutral25
        // pressed
        secondaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.04)  // this tries to simulate `neutral100`
        secondaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return secondaryButtonConfiguration
    }
}

// attaches haptic feedback to a button press
private final class ButtonFeedbackGeneratorHandler: NSObject {

    @objc private func didTouchUpInside() {
        FeedbackGeneratorAdapter.buttonTapped()
    }

    // `associatedObjectKey` is a unique address when accessed
    // via `&`, so we just map a key ("random address") to
    // a value (or "instance variable") `buttonFeedbackGeneratorHandler`
    // so we can retain it to fire `didTouchUpInside` func
    private static var associatedObjectKey: UInt8 = 0
    static func attach(toButton button: UIControl) {
        let buttonFeedbackGeneratorHandler = ButtonFeedbackGeneratorHandler()
        objc_setAssociatedObject(
            button,
            &associatedObjectKey,
            buttonFeedbackGeneratorHandler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        button.addTarget(
            buttonFeedbackGeneratorHandler,
            action: #selector(didTouchUpInside),
            for: .touchUpInside
        )
    }
}

#if DEBUG

import SwiftUI

private struct PrimaryButtonViewRepresentable: UIViewRepresentable {
    let theme: FinancialConnectionsTheme
    let enabled: Bool

    func makeUIView(context: Context) -> StripeUICore.Button {
        let button = StripeUICore.Button.primary(theme: theme)
        button.title = "primary | \(theme.rawValue) | \(enabled ? "enabled" : "disabled")"
        return button
    }

    func updateUIView(_ uiView: StripeUICore.Button, context: Context) {
        uiView.isEnabled = enabled
    }
}

private struct SecondaryButtonViewRepresentable: UIViewRepresentable {
    let enabled: Bool

    func makeUIView(context: Context) -> StripeUICore.Button {
        let button = StripeUICore.Button.secondary()
        button.title = "secondary | \(enabled ? "enabled" : "disabled")"
        return button
    }

    func updateUIView(_ uiView: StripeUICore.Button, context: Context) {
        uiView.isEnabled = enabled
    }
}

struct ButtonViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButtonViewRepresentable(theme: .light, enabled: true)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(theme: .light, enabled: false)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(theme: .linkLight, enabled: true)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(theme: .linkLight, enabled: false)
                .frame(height: 64)
                .padding()
            SecondaryButtonViewRepresentable(enabled: true)
                .frame(height: 64)
                .padding()
            SecondaryButtonViewRepresentable(enabled: false)
                .frame(height: 64)
                .padding()
        }
    }
}

#endif
