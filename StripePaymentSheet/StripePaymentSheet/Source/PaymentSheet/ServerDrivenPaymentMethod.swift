//
//  ServerDrivenPaymentMethod.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
import UIKit

/// A payment method PaymentSheet renders from the `display` of its `payment_method_availability.payment_methods` entry,
/// rather than from SDK code for its `STPPaymentMethodType`. It's displayed like an external payment method and
/// confirmed with `STPPaymentHandler` as an `.unknown` type, which follows `next_action[redirect_to_url]`.
struct ServerDrivenPaymentMethod {
    /// The payment method type, e.g. "paypal", confirmed as `payment_method_data[type]`. Unique among a session's payment methods.
    let type: String
    /// Localized by the server to the header's `display_language`.
    let label: String
    let subtitle: String?
    let icon: Icon

    struct Icon {
        /// One resolution of an icon image.
        struct File: Hashable {
            let url: URL
            /// Pixels per point, with the art fit inside the 30x20pt icon box at that scale.
            let scale: Int
        }
        /// The icon image at several scales. Never empty.
        let light: [File]
        /// Like `light`, never empty.
        let dark: [File]?
        /// If true, the image is tinted to the foreground color, like the SDK's bank and card icons.
        let isTemplate: Bool

        /// Returns the files for the background, falling back to `light` as the contract specifies.
        func files(forDarkBackground: Bool) -> [File] {
            return forDarkBackground ? dark ?? light : light
        }

        /// Returns the file for the background with the smallest scale at or above `screenScale`, else the one with the largest scale.
        func file(forDarkBackground: Bool, screenScale: CGFloat) -> File {
            return Self.file(in: files(forDarkBackground: forDarkBackground), forScreenScale: screenScale)
        }

        /// Returns the file in `files` with the smallest scale at or above `screenScale`, else the one with the largest scale.
        static func file(in files: [File], forScreenScale screenScale: CGFloat) -> File {
            // Safe to force-unwrap: `ServerDrivenPaymentMethod.init` throws for an icon without files.
            let largest = files.max { $0.scale < $1.scale }!
            return files
                .filter { CGFloat($0.scale) >= screenScale }
                .min { $0.scale < $1.scale } ?? largest
        }
    }

    /// The first part of a description this SDK can't render, e.g. "icon_rendering:unparsable".
    struct UnsupportedValue: Error, Equatable {
        let value: String
    }

    /// Returns the payment method for a `type` described by `display`, or throws `UnsupportedValue` if this SDK can't render it.
    /// The server should only send what this SDK version supports, so a throw means its capability table is wrong.
    init(type: String, display: MobileSession.PaymentMethodDisplay) throws {
        let isTemplate: Bool
        switch display.icon.rendering {
        case .original:
            isTemplate = false
        case .template:
            isTemplate = true
        case .unparsable:
            throw UnsupportedValue(value: "icon_rendering:unparsable")
        }
        guard !type.isEmpty else {
            throw UnsupportedValue(value: "type:empty")
        }

        let icon = display.icon
        self.type = type
        self.label = display.label
        self.subtitle = display.subtitle
        self.icon = Icon(
            light: try Self.files(icon.light),
            dark: try icon.dark.map(Self.files),
            isTemplate: isTemplate
        )
    }

    private static func files(_ files: [MobileSession.IconFile]) throws -> [Icon.File] {
        guard !files.isEmpty else {
            throw UnsupportedValue(value: "icon:no_files")
        }
        return try files.map { file in
            guard let url = URL(string: file.url), url.scheme == "https" else {
                throw UnsupportedValue(value: "icon:invalid_url")
            }
            guard file.scale > 0 else {
                throw UnsupportedValue(value: "icon:invalid_scale")
            }
            return Icon.File(url: url, scale: file.scale)
        }
    }

    /// The screen's scale, which picks the icon file to download.
    static var screenScale: CGFloat {
        #if os(visionOS)
        return 1.0
        #else
        return UIScreen.main.scale
        #endif
    }

    /// The size of the box `RowButton` draws payment method icons in.
    static let iconSize = CGSize(width: 30, height: 20)

    /// A clear `iconSize` image, for an icon that hasn't downloaded and that the SDK has no image of its own for.
    static let blankIcon: UIImage = UIGraphicsImageRenderer(size: iconSize).image { _ in }

    /// Returns the icon for the background, decoded at its file's scale, or a placeholder if it isn't cached.
    /// - With an `updateHandler`, as rows use it, the placeholder is `fallbackImage` and the download calls `updateHandler`.
    ///   If the download fails, the row keeps the placeholder.
    /// - Without one, as for the images FlowController and Embedded give the merchant, the placeholder is `blankIcon`,
    ///   and vending it is logged. The merchant's image isn't updated, so the load-time prefetch should have cached the icon.
    func makeImage(
        forDarkBackground: Bool,
        iconStyle: PaymentSheet.Appearance.IconStyle,
        updateHandler: DownloadManager.UpdateImageHandler?,
        downloadManager: DownloadManager = .sharedManager,
        analyticsClient: STPAnalyticsClient = .sharedClient,
        screenScale: CGFloat = Self.screenScale
    ) -> UIImage {
        let file = icon.file(forDarkBackground: forDarkBackground, screenScale: screenScale)
        let placeholder = updateHandler == nil ? Self.blankIcon : fallbackImage(forDarkBackground: forDarkBackground, iconStyle: iconStyle)
        let image = downloadManager.downloadImage(url: file.url, placeholder: placeholder, updateHandler: updateHandler, scale: CGFloat(file.scale))
        if updateHandler == nil, image === placeholder {
            analyticsClient.logPaymentSheetEvent(
                event: .paymentSheetServerDrivenIconPlaceholderVended,
                params: ["payment_method_type": type]
            )
        }
        return image
    }

    /// Returns the SDK's own icon for `type` if it has one with the same tinting, else `blankIcon`.
    func fallbackImage(forDarkBackground: Bool, iconStyle: PaymentSheet.Appearance.IconStyle) -> UIImage {
        let nativeType = STPPaymentMethod.type(from: type)
        guard nativeType != .unknown,
              nativeType.iconRequiresTinting == icon.isTemplate,
              let image = nativeType.makeImage(forDarkBackground: forDarkBackground, iconStyle: iconStyle) else {
            return Self.blankIcon
        }
        return image
    }

    /// Starts downloading the light and dark icons at the files `makeImage` picks.
    /// Rows, and the images FlowController and Embedded give the merchant, are then usually cached before they're built.
    func prefetchIcons(downloadManager: DownloadManager = .sharedManager, screenScale: CGFloat = Self.screenScale) {
        let files = Set([false, true].map { icon.file(forDarkBackground: $0, screenScale: screenScale) })
        for file in files {
            // Passing a non-nil updateHandler starts a best-effort download that fills the in-memory cache.
            _ = downloadManager.downloadImage(url: file.url, placeholder: nil, updateHandler: { _ in }, scale: CGFloat(file.scale))
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
