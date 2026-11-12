//
//  ServerDrivenPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
import UIKit

/// A payment method PaymentSheet renders and confirms from the server's `mobile_session.payment_methods` description,
/// rather than from SDK code for its `STPPaymentMethodType`. It's displayed like an external payment method and
/// confirmed like a Stripe payment method.
struct ServerDrivenPaymentMethod {
    /// The payment method type, e.g. "demo_pay". Unique among a session's payment methods.
    let type: String
    /// Localized by the server to the header's `display_language`.
    let label: String
    let subtitle: String?
    let icon: Icon
    /// The `payment_method_data[type]` to confirm with.
    let paymentMethodDataType: String
    /// How `PaymentConfirmer` confirms it: its next actions and status rules, from the description's `confirm`.
    let confirmation: ConfirmationMetadata

    struct Icon {
        struct Image: Hashable {
            let url: URL

            /// Returns the URL to download and the scale to decode it at, for an icon `height` points tall: `url` through
            /// Stripe's image proxy at that height and the screen's scale.
            func download(height: Int, dpr: Int = StripeImageProxy.screenDPR) -> (url: URL, scale: CGFloat) {
                return (StripeImageProxy.url(for: url, format: .png, height: height, dpr: dpr), CGFloat(dpr))
            }
        }
        let light: Image
        let dark: Image?
        let outlinedLight: Image?
        let outlinedDark: Image?
        /// If true, the image is tinted to the foreground color, like the SDK's bank and card icons.
        let isTemplate: Bool

        /// Returns the image for the background and icon style, falling back as the contract specifies.
        func image(forDarkBackground: Bool, iconStyle: PaymentSheet.Appearance.IconStyle) -> Image {
            switch (iconStyle, forDarkBackground) {
            case (.filled, false):
                return light
            case (.filled, true):
                return dark ?? light
            case (.outlined, false):
                return outlinedLight ?? light
            case (.outlined, true):
                return outlinedDark ?? dark ?? light
            }
        }
    }

    /// The first part of a `mobile_session.payment_methods` entry this SDK can't render, e.g. "mandate_data:online_inferred".
    struct UnsupportedValue: Error, Equatable {
        let value: String
    }

    /// Returns the payment method for `paymentMethod`, or throws `UnsupportedValue` if this SDK can't render or confirm it.
    /// The server should only send what this SDK version supports, so a throw means its capability table is wrong.
    init(_ paymentMethod: MobileSession.PaymentMethod) throws {
        // Every form element needs SDK support, and v1 supports none.
        for element in paymentMethod.form.elements {
            switch element.type {
            case .unparsable:
                throw UnsupportedValue(value: "form_element:unparsable")
            }
        }
        // PaymentSheet builds confirm params in code, and doesn't send mandate data for these yet.
        switch paymentMethod.confirm.mandateData {
        case .none:
            break
        case .onlineInferred, .onlineInferredWhenSettingUp, .unparsable:
            throw UnsupportedValue(value: "mandate_data:\(paymentMethod.confirm.mandateData.rawValue)")
        }
        // The same mapping as a served `payment_method_confirmations` entry.
        let confirmation: ConfirmationMetadata
        do {
            confirmation = try ConfirmationMetadata(wire: paymentMethod.confirm, type: paymentMethod.type)
        } catch let error as ConfirmationMetadata.WireError {
            throw UnsupportedValue(value: error.description)
        }
        switch paymentMethod.savedPaymentMethods {
        case .unsupported:
            break
        case .unparsable:
            throw UnsupportedValue(value: "saved_payment_methods:unparsable")
        }
        let isTemplate: Bool
        switch paymentMethod.display.icon.rendering {
        case .original:
            isTemplate = false
        case .template:
            isTemplate = true
        case .unparsable:
            throw UnsupportedValue(value: "icon_rendering:unparsable")
        }
        guard !paymentMethod.type.isEmpty, !paymentMethod.confirm.paymentMethodDataType.isEmpty else {
            throw UnsupportedValue(value: "type:empty")
        }

        let icon = paymentMethod.display.icon
        self.type = paymentMethod.type
        self.label = paymentMethod.display.label
        self.subtitle = paymentMethod.display.subtitle
        self.icon = Icon(
            light: try Self.image(icon.light),
            dark: try icon.dark.map(Self.image),
            outlinedLight: try icon.outlinedLight.map(Self.image),
            outlinedDark: try icon.outlinedDark.map(Self.image),
            isTemplate: isTemplate
        )
        self.paymentMethodDataType = paymentMethod.confirm.paymentMethodDataType
        self.confirmation = confirmation
    }

    private static func image(_ image: MobileSession.IconImage) throws -> Icon.Image {
        guard let url = URL(string: image.url), url.scheme == "https" else {
            throw UnsupportedValue(value: "icon:invalid_url")
        }
        return Icon.Image(url: url)
    }

    /// The height in points to fetch icons at. `RowButton` draws icons in a 30x20pt box. The horizontal layout's
    /// 12pt icons, and the images FlowController and Embedded give the merchant, scale this down rather than fetch again.
    static let iconHeight: Int = 20

    /// Returns the icon for the background and icon style. Returns a placeholder until the image downloads, then calls `updateHandler`.
    func makeImage(forDarkBackground: Bool, iconStyle: PaymentSheet.Appearance.IconStyle, updateHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
        let download = icon.image(forDarkBackground: forDarkBackground, iconStyle: iconStyle).download(height: Self.iconHeight)
        return DownloadManager.sharedManager.downloadImage(
            url: download.url,
            placeholder: nil,
            updateHandler: updateHandler,
            scale: download.scale
        )
    }

    /// Starts downloading each icon `iconStyle` can draw, on a light or a dark background, at the size `makeImage` fetches.
    /// Rows, and the images FlowController and Embedded give the merchant, are then usually cached before they're built.
    func prefetchIcons(iconStyle: PaymentSheet.Appearance.IconStyle, downloadManager: DownloadManager = .sharedManager) {
        let images = Set([false, true].map { icon.image(forDarkBackground: $0, iconStyle: iconStyle) })
        for image in images {
            let download = image.download(height: Self.iconHeight)
            // Passing a non-nil updateHandler starts a best-effort download that fills the in-memory cache.
            _ = downloadManager.downloadImage(url: download.url, placeholder: nil, updateHandler: { _ in }, scale: download.scale)
        }
    }
}

/// Like `ExternalPaymentOption`, equality is based solely on `type`, which is unique within a session.
extension ServerDrivenPaymentMethod: Equatable {
    static func == (lhs: ServerDrivenPaymentMethod, rhs: ServerDrivenPaymentMethod) -> Bool {
        return lhs.type == rhs.type
    }
}

extension ServerDrivenPaymentMethod: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
