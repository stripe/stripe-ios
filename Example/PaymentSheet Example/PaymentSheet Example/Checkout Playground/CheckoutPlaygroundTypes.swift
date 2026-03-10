//
//  CheckoutPlaygroundTypes.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Foundation

@available(iOS 15.0, *)
enum CheckoutPlayground {
    enum SessionMode: String, CaseIterable, Identifiable {
        case payment
        case subscription
        case setup

        var id: String { rawValue }
    }

    enum Currency: String, CaseIterable, Identifiable {
        case usd
        case eur
        case gbp
        case cad
        case aud
        case jpy

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .usd, .cad, .aud:
                return "$"
            case .eur:
                return "€"
            case .gbp:
                return "£"
            case .jpy:
                return "¥"
            }
        }

        var isZeroDecimal: Bool {
            return self == .jpy
        }
    }

    enum CustomerType: String, CaseIterable, Identifiable {
        case returning
        case new
        case guest

        var id: String { rawValue }
    }

    struct LineItemConfig: Identifiable {
        let id = UUID()
        var name: String
        var unitAmount: Int
        var quantity: Int

        static let defaults: [LineItemConfig] = [
            LineItemConfig(name: "Classic T-Shirt", unitAmount: 3500, quantity: 2),
            LineItemConfig(name: "Zip-Up Hoodie", unitAmount: 5000, quantity: 1),
        ]
    }
}
