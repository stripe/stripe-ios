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
    static func primary(appearance: FinancialConnectionsAppearance) -> StripeUICore.Button {
        let button = Button(configuration: .financialConnectionsPrimary(appearance: appearance))
        if appearance.colors == .link {
            button.layer.shadowColor = UIColor(red: 48 / 255, green: 49 / 255, blue: 61 / 255, alpha: 1).cgColor
            button.layer.shadowRadius = 2.5
            button.layer.shadowOpacity = 0.12
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            // Figma: linear-gradient(180deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 100%)
            // overlaid on the primary button color (#171717).
            let gradientOverlay = LinkPrimaryButtonGradientView(cornerRadius: appearance.buttonHeight / 2)
            gradientOverlay.translatesAutoresizingMaskIntoConstraints = false
            button.insertSubview(gradientOverlay, at: 0)
            NSLayoutConstraint.activate([
                gradientOverlay.topAnchor.constraint(equalTo: button.topAnchor),
                gradientOverlay.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                gradientOverlay.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                gradientOverlay.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
        } else {
            button.layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
            button.layer.shadowRadius = 5 / UIScreen.main.nativeScale
            button.layer.shadowOpacity = 0.25
            button.layer.shadowOffset = CGSize(width: 0, height: 2 / UIScreen.main.nativeScale)
        }
        ButtonFeedbackGeneratorHandler.attach(toButton: button)
        return button
    }

    static func secondary(appearance: FinancialConnectionsAppearance) -> StripeUICore.Button {
        let button = Button(configuration: .financialConnectionsSecondary(appearance: appearance))
        ButtonFeedbackGeneratorHandler.attach(toButton: button)
        return button
    }
}

extension StripeUICore.Button.Configuration {

    fileprivate static func financialConnectionsPrimary(appearance: FinancialConnectionsAppearance) -> StripeUICore.Button.Configuration {
        var primaryButtonConfiguration = Button.Configuration.primary()
        primaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        primaryButtonConfiguration.cornerRadius = appearance.colors == .link ? appearance.buttonHeight / 2 : 12
        // default
        primaryButtonConfiguration.backgroundColor = appearance.colors.primary
        primaryButtonConfiguration.foregroundColor = appearance.colors.primaryAccent
        // disabled
        primaryButtonConfiguration.disabledBackgroundColor = appearance.colors.primary
        primaryButtonConfiguration.disabledForegroundColor = appearance.colors.primaryAccent.withAlphaComponent(0.4)
        // pressed
        primaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.23)  // this tries to simulate `brand600`
        primaryButtonConfiguration.colorTransforms.highlightedForeground = nil
        return primaryButtonConfiguration
    }

    fileprivate static func financialConnectionsSecondary(appearance: FinancialConnectionsAppearance) -> StripeUICore.Button.Configuration {
        var secondaryButtonConfiguration = Button.Configuration.secondary()
        secondaryButtonConfiguration.font = FinancialConnectionsFont.label(.largeEmphasized).uiFont
        secondaryButtonConfiguration.cornerRadius = 12.0
        // default
        secondaryButtonConfiguration.foregroundColor = FinancialConnectionsAppearance.Colors.textDefault
        if appearance.colors == .link {
            secondaryButtonConfiguration.backgroundColor = .clear
            secondaryButtonConfiguration.disabledBackgroundColor = .clear
            secondaryButtonConfiguration.colorTransforms.highlightedBackground = nil
        } else {
            secondaryButtonConfiguration.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
            secondaryButtonConfiguration.disabledBackgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
            secondaryButtonConfiguration.colorTransforms.highlightedBackground = .darken(amount: 0.04)
        }
        // disabled
        secondaryButtonConfiguration.disabledForegroundColor = FinancialConnectionsAppearance.Colors.textDefault.withAlphaComponent(0.4)
        // pressed
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

// Renders the Figma gradient sheen (rgba(255,255,255,0.08)→0) over the Link primary button.
// Inserted as subview at index 0 so it sits above the button background but below the title.
private final class LinkPrimaryButtonGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }  // swiftlint:disable:this static_over_final_class

    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [
            UIColor(white: 1, alpha: 0.08).cgColor,
            UIColor(white: 1, alpha: 0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

#if DEBUG

import SwiftUI

private struct PrimaryButtonViewRepresentable: UIViewRepresentable {
    let appearance: FinancialConnectionsAppearance
    let enabled: Bool

    func makeUIView(context: Context) -> StripeUICore.Button {
        let button = StripeUICore.Button.primary(appearance: appearance)
        button.title = "primary | \(appearance == .stripe ? "stripe" : "link") | \(enabled ? "enabled" : "disabled")"
        return button
    }

    func updateUIView(_ uiView: StripeUICore.Button, context: Context) {
        uiView.isEnabled = enabled
    }
}

private struct SecondaryButtonViewRepresentable: UIViewRepresentable {
    let appearance: FinancialConnectionsAppearance
    let enabled: Bool

    func makeUIView(context: Context) -> StripeUICore.Button {
        let button = StripeUICore.Button.secondary(appearance: appearance)
        button.title = "secondary | \(appearance == .stripe ? "stripe" : "link") | \(enabled ? "enabled" : "disabled")"
        return button
    }

    func updateUIView(_ uiView: StripeUICore.Button, context: Context) {
        uiView.isEnabled = enabled
    }
}

struct ButtonViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButtonViewRepresentable(appearance: .stripe, enabled: true)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(appearance: .stripe, enabled: false)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(appearance: .link, enabled: true)
                .frame(height: 64)
                .padding()
            PrimaryButtonViewRepresentable(appearance: .link, enabled: false)
                .frame(height: 64)
                .padding()
            SecondaryButtonViewRepresentable(appearance: .stripe, enabled: true)
                .frame(height: 64)
                .padding()
            SecondaryButtonViewRepresentable(appearance: .stripe, enabled: false)
                .frame(height: 64)
                .padding()
            SecondaryButtonViewRepresentable(appearance: .link, enabled: true)
                .frame(height: 44)
                .padding()
            SecondaryButtonViewRepresentable(appearance: .link, enabled: false)
                .frame(height: 44)
                .padding()
        }
    }
}

#endif
