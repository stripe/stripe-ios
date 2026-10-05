//
//  HunchTheme.swift
//  HunchPredictionDemo
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI
import UIKit

enum Hunch {
    static let background = Color.white
    static let surface = Color(uiColor: .hunchSurface)
    static let hairline = Color(red: 0.91, green: 0.92, blue: 0.94)
    static let text = Color(uiColor: .hunchText)
    static let secondary = Color(red: 0.42, green: 0.45, blue: 0.5)
    static let brand = Color(uiColor: .hunchBrand)
    static let yes = Color(uiColor: .hunchYes)
    static let yesTint = Color(red: 0.9, green: 0.97, blue: 0.94)
    static let no = Color(uiColor: .hunchNo)
    static let noTint = Color(red: 0.99, green: 0.93, blue: 0.93)

    /// Line colors for multi-outcome markets, in outcome order.
    static let outcomePalette: [Color] = [
        Color(uiColor: .hunchBrand),
        Color(red: 0.49, green: 0.36, blue: 0.99),
        Color(red: 1.0, green: 0.54, blue: 0.0),
        Color(red: 0.18, green: 0.5, blue: 0.93),
    ]
}

extension UIColor {
    static let hunchBrand = UIColor(red: 0.0, green: 0.659, blue: 0.455, alpha: 1)
    static let hunchYes = UIColor(red: 0.0, green: 0.62, blue: 0.43, alpha: 1)
    static let hunchNo = UIColor(red: 0.9, green: 0.28, blue: 0.3, alpha: 1)
    static let hunchText = UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)
    static let hunchSurface = UIColor(red: 0.965, green: 0.969, blue: 0.976, alpha: 1)
}

extension Font {
    static func hunch(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func hunchNumber(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Scales slightly on press.
struct HunchPressStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

enum Side: String {
    case yes = "Yes"
    case no = "No"

    var color: Color { self == .yes ? Hunch.yes : Hunch.no }
    var tint: Color { self == .yes ? Hunch.yesTint : Hunch.noTint }
}

/// Yes/No price pill. Flashes when the price changes.
struct SidePriceButton: View {
    let side: Side
    let cents: Int
    var compact = false
    let action: () -> Void

    @State private var flash = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(side.rawValue)
                Text("\(cents)¢")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(cents)))
            }
            .font(.hunch(compact ? 14 : 16, .semibold))
            .foregroundStyle(side.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 8 : 12)
            .background(side.tint, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(side.color.opacity(flash ? 0.9 : 0), lineWidth: 1.5)
            )
        }
        .buttonStyle(HunchPressStyle())
        .animation(.snappy(duration: 0.25), value: cents)
        .onChange(of: cents) {
            flash = true
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) { flash = false }
        }
    }
}

struct HunchPrimaryButton: View {
    let title: String
    var color: Color = Hunch.text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.hunch(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(HunchPressStyle())
    }
}

struct HunchWordmark: View {
    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Hunch.brand)
                    .frame(width: 26, height: 26)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Text("hunch")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Hunch.text)
                .tracking(-0.5)
        }
    }
}

extension Double {
    var dollars: String { formatted(.currency(code: "USD")) }

    var signedDollars: String {
        let formatted = abs(self).formatted(.currency(code: "USD"))
        return self >= 0 ? "+\(formatted)" : "-\(formatted)"
    }
}

extension EmbeddedComponentManager.Appearance {
    /// Themes embedded components to Hunch's light look.
    static func hunch(surface: EmbeddedComponentSurface) -> Self {
        var appearance = Self.default
        appearance.spacingUnit = 10
        appearance.colors.background = surface == .page ? .white : .hunchSurface
        appearance.colors.offsetBackground = surface == .page ? .hunchSurface : .white
        appearance.colors.formBackground = .white
        appearance.colors.text = .hunchText
        appearance.colors.secondaryText = UIColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1)
        appearance.colors.border = UIColor(red: 0.89, green: 0.9, blue: 0.92, alpha: 1)
        appearance.colors.primary = .hunchBrand
        appearance.colors.actionPrimaryText = .hunchBrand
        appearance.colors.actionSecondaryText = .hunchText
        appearance.colors.formHighlightBorder = .hunchBrand
        appearance.colors.formAccent = .hunchBrand
        appearance.colors.danger = .hunchNo

        appearance.buttonPrimary.colorBackground = .hunchText
        appearance.buttonPrimary.colorBorder = .hunchText
        appearance.buttonPrimary.colorText = .white
        appearance.buttonSecondary.colorBackground = .hunchSurface
        appearance.buttonSecondary.colorBorder = .hunchSurface
        appearance.buttonSecondary.colorText = .hunchText
        appearance.buttonDefaults.paddingVertical = 14
        appearance.buttonDefaults.labelTypography = .style(16, .semibold)

        // Badge colors must be opaque; alpha is dropped when the appearance is sent to the web view.
        appearance.badgeSuccess.colorBackground = UIColor(red: 0.9, green: 0.97, blue: 0.94, alpha: 1)
        appearance.badgeSuccess.colorText = .hunchYes
        appearance.badgeSuccess.colorBorder = UIColor(red: 0.9, green: 0.97, blue: 0.94, alpha: 1)
        appearance.badgeNeutral.colorBackground = .hunchSurface
        appearance.badgeNeutral.colorText = UIColor(red: 0.3, green: 0.33, blue: 0.38, alpha: 1)
        appearance.badgeNeutral.colorBorder = .hunchSurface

        appearance.cornerRadius.base = 14
        appearance.cornerRadius.form = 12
        appearance.cornerRadius.button = 14
        appearance.cornerRadius.badge = 8
        appearance.cornerRadius.overlay = 20

        appearance.typography.fontSizeBase = 16
        appearance.typography.headingLg = .style(24, .bold)
        appearance.typography.headingMd = .style(20, .bold)
        return appearance
    }
}
