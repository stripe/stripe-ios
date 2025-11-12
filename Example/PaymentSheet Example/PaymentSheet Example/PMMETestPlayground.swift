//
//  PMMETestPlayground.swift
//  PaymentSheet Example
//
//  Created by George Birch on 10/15/25.
//

@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct PMMETestPlayground: View {

    private var config: PaymentMethodMessagingElement.Configuration {
        .init(
            amount: amount,
            currency: country.currency,
            countryCode: country.stringValue,
            paymentMethodTypes: paymentMethodTypes,
            appearance: .init(
                style: style,
                font: fontSetting == .default ? PaymentMethodMessagingElement.Appearance().font.withSize(fontSize) : UIFont(name: fontSetting.stringValue, size: fontSize),
                textColor: textColor == .default ? PaymentMethodMessagingElement.Appearance().textColor : UIColor(hex: textColor.rawValue),
                infoIconColor: infoIconColor == .default ? PaymentMethodMessagingElement.Appearance().infoIconColor : UIColor(hex: infoIconColor.rawValue)
            ))
    }
    private var paymentMethodTypes: [STPPaymentMethodType] {
        [
            klarna == .on ? .klarna : nil,
            affirm == .on ? .affirm : nil,
            afterpayClearpay == .on ? .afterpayClearpay : nil,
        ].compactMap { $0 }
    }

    // Appearance
    @State private var style = PaymentMethodMessagingElement.Appearance.UserInterfaceStyle.automatic
    @State private var fontSetting = PMMEPlaygroundFontSetting.default
    @State private var fontSize: CGFloat = PaymentMethodMessagingElement.Appearance().font.pointSize
    @State private var textColor = PMMEPlaygroundColorSetting.default
    @State private var infoIconColor = PMMEPlaygroundColorSetting.default

    // Config
    @State private var amount = 5000
    @State private var country = PMMEPlaygroundCountrySetting.US
    @State private var klarna = PMMEPlaygroundToggle.on
    @State private var affirm = PMMEPlaygroundToggle.on
    @State private var afterpayClearpay = PMMEPlaygroundToggle.off
    @State private var playgroundBackground = PMMEPlaygroundColorSetting.default
    @State private var implementation = PMMEPlaygroundImplSetting.config

    // ViewData
    @State private var viewData: PaymentMethodMessagingElement.ViewData?
    @State private var viewDataIntegrationText: String? // text to show for viewdata integration style

    @State private var showUiKitSheet = false

    var body: some View {
        ScrollView {
            // Appearance
            Text("Appearance")
            PMMEPlaygroundSettingView(title: "style", selectedOption: $style, onChange: configure)
            PMMEPlaygroundSettingView(title: "textColor", selectedOption: $textColor, onChange: configure)
            PMMEPlaygroundSettingView(title: "infoIconColor", selectedOption: $infoIconColor, onChange: configure)
            PMMEPlaygroundSettingView(title: "font", selectedOption: $fontSetting, onChange: configure)
            HStack {
                Text("font size: \(Int(fontSize))")
                Slider(value: $fontSize, in: 8...30)
                    .onChange(of: fontSize) { _ in configure() }
            }
            Divider()

            // Config
            Text("Configuration")
            HStack {
                Text("amount: \(amount)")
                Stepper("", value: $amount, in: 0...15000, step: 1000)
                    .onChange(of: amount) { _ in configure() }
            }
            PMMEPlaygroundSettingView(title: "country", selectedOption: $country, onChange: configure)
            PMMEPlaygroundSpacedText(part1: "↳ currency:", part2: country.currency)
            PMMEPlaygroundSpacedText(part1: "↳ countryCode:", part2: country.stringValue)
            PMMEPlaygroundSpacedText(part1: "↳ publishableKey:", part2: country.publishableKey.dropLast(90) + "...")
            PMMEPlaygroundSettingView(title: "klarna", selectedOption: $klarna, onChange: configure)
            PMMEPlaygroundSettingView(title: "affirm", selectedOption: $affirm, onChange: configure)
            PMMEPlaygroundSettingView(title: "afterpayClearpay", selectedOption: $afterpayClearpay, onChange: configure)
            PMMEPlaygroundSpacedText(part1: "↳ paymentMethodTypes:", part2: "\(paymentMethodTypes.map { $0.identifier })\(paymentMethodTypes.isEmpty ? " (default/dynamic payment methods)" : "")")
            Divider()

            // Playground
            Text("Misc")
            PMMEPlaygroundSettingView(title: "playground background", selectedOption: $playgroundBackground, onChange: configure)
            PMMEPlaygroundSettingView(title: "integration style", selectedOption: $implementation, onChange: configure)
            HStack {
                Text("UIKit intregation")
                Spacer()
                Button("Launch") {
                    showUiKitSheet = true
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showUiKitSheet) {
                    UIKitVC(config: config)
                }
            }
            Divider()

            switch implementation {
            case .config:
                PaymentMethodMessagingElement.View(configuration: config)
            case .content:
                PaymentMethodMessagingElement.View(configuration: config) { phase in
                    switch phase {
                    case .failed(let error):
                        Text(error.localizedDescription)
                    case .loaded(let view):
                        view
                    case .loading:
                        Text("loading")
                    case .noContent:
                        Text("no content")
                    }
                }
            case .viewData:
                if let viewData {
                    PaymentMethodMessagingElement.View(viewData)
                } else if let viewDataIntegrationText {
                    Text(viewDataIntegrationText)
                } else {
                    Text("loading")
                        .onAppear {
                            configure()
                        }
                }
            }
            Text("Hi! I'm here to show whether or not the element's height is correctly set in SwiftUI")
                .background(.blue)
        }
        .padding(.horizontal)
        .background(playgroundBackground == .default ? nil : Color(UIColor(hex: playgroundBackground.rawValue)))
        .onAppear {
            STPAPIClient.shared.publishableKey = country.publishableKey
        }
        .onChange(of: country) { _ in
            STPAPIClient.shared.publishableKey = country.publishableKey
        }
        .font(.system(size: 14))
    }

    // Manual configuration for MVVM-style integration
    private func configure() {
        guard implementation == .viewData else { return }
        viewDataIntegrationText = "loading"
        Task { @MainActor in
            switch await PaymentMethodMessagingElement.create(configuration: config) {
            case let .success(element):
                self.viewData = element.viewData
                viewDataIntegrationText = nil
            case .noContent:
                self.viewData = nil
                viewDataIntegrationText = "no content"
            case let .failed(error):
                self.viewData = nil
                viewDataIntegrationText = "something went wrong: \(error.localizedDescription)"
            }
        }
    }
}

@available(iOS 15.0, *)
struct PMMEPlaygroundSettingView<T: PMMEPlaygroundSetting>: View {

    let title: String
    @Binding var selectedOption: T
    let onChange: () -> Void

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: $selectedOption) {
                ForEach(T.allCases) {
                    Text($0.stringValue).tag($0)
                }
            }
            .onChange(of: selectedOption) { _ in onChange() }
            .pickerStyle(.segmented)
        }
    }
}

struct PMMEPlaygroundSpacedText: View {
    let part1: String
    let part2: String

    var body: some View {
        HStack {
            Text(part1)
            Spacer()
            Text(part2)
        }
    }
}

protocol PMMEPlaygroundSetting: Identifiable, CaseIterable, Hashable where AllCases: RandomAccessCollection {
    var stringValue: String { get }
}

extension PMMEPlaygroundSetting {
    var stringValue: String { return String(describing: self) }
    public var id: String { stringValue }
}

extension PaymentMethodMessagingElement.Appearance.UserInterfaceStyle: @retroactive Identifiable {}
extension PaymentMethodMessagingElement.Appearance.UserInterfaceStyle: @retroactive CaseIterable {}
extension PaymentMethodMessagingElement.Appearance.UserInterfaceStyle: PMMEPlaygroundSetting {
    public static var allCases: [Self] = [.alwaysLight, .alwaysDark, .automatic, .flat]
}

enum PMMEPlaygroundToggle: PMMEPlaygroundSetting {
    case on
    case off
}

enum PMMEPlaygroundFontSetting: PMMEPlaygroundSetting {
    case `default`
    case americanTypewriter

    var stringValue: String {
        switch self {
        case .americanTypewriter: "AmericanTypewriter"
        case .default: "default"
        }
    }
}

enum PMMEPlaygroundColorSetting: UInt, PMMEPlaygroundSetting {
    case `default` = 0
    case green = 0x87a96b
    case pink = 0xffa7b6
}

enum PMMEPlaygroundCountrySetting: PMMEPlaygroundSetting {
    case US
    case GB
    case FR
    case AU

    var currency: String {
        switch self {
        case .US: "usd"
        case .GB: "gbp"
        case .FR: "eur"
        case .AU: "aud"
        }
    }

    var publishableKey: String {
        switch self {
        case .US: "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"
        case .GB: "pk_test_51KmkHbGoesj9fw9QAZJlz1qY4dns8nFmLKc7rXiWKAIj8QU7NPFPwSY1h8mqRaFRKQ9njs9pVJoo2jhN6ZKSDA4h00mjcbGF7b"
        case .FR: "pk_test_51JtgfQKG6vc7r7YCU0qQNOkDaaHrEgeHgGKrJMNfuWwaKgXMLzPUA1f8ZlCNPonIROLOnzpUnJK1C1xFH3M3Mz8X00Q6O4GfUt"
        case .AU: "pk_test_51KaoFxCPXw4rvZpfi7MgGvQHAyqydlZgq7qfazb65457ApNZVN12LdVmiZh0bmDfgBEDUlXtSM72F9rPweMN0QJP00hVaYXMkx"
        }
    }
}

extension UIColor {
    convenience init(hex: UInt) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

enum PMMEPlaygroundImplSetting: PMMEPlaygroundSetting {
    case config
    case content
    case viewData
}

struct UIKitVC: UIViewControllerRepresentable {

    let config: PaymentMethodMessagingElement.Configuration

    func makeUIViewController(context: Context) -> some UIViewController {
        return PMMEPlaygroundUIViewController(config: config)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
}
