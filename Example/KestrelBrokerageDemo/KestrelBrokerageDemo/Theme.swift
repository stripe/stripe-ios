//
//  Theme.swift
//  KestrelBrokerageDemo
//

import SwiftUI
import UIKit

enum Theme {
    static let background = Color.black
    static let card = Color(uiColor: .card)
    static let cardRaised = Color(white: 0.15)
    static let hairline = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let gain = Color(uiColor: .gain)
    static let loss = Color(uiColor: .loss)

    static func trend(_ isUp: Bool) -> Color { isUp ? gain : loss }
}

extension UIColor {
    static let gain = UIColor(red: 0.0, green: 0.784, blue: 0.020, alpha: 1)
    static let loss = UIColor(red: 1.0, green: 0.314, blue: 0.0, alpha: 1)
    /// Matches the elevated dark background iOS uses for page sheets, so native
    /// sheets and embedded web content read as one surface.
    static let card = UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1)
}

extension Font {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Scales slightly on press, like Kestrel's primary controls.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PillButton: View {
    let title: String
    var color: Color = Theme.gain
    var foreground: Color = .black
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color, in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}
