import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "affirm_mark" asset catalog image resource.
    static let affirmMark = ImageResource(name: "affirm_mark", bundle: resourceBundle)

    /// The "afterpay_icon_info" asset catalog image resource.
    static let afterpayIconInfo = ImageResource(name: "afterpay_icon_info", bundle: resourceBundle)

    /// The "afterpay_mark" asset catalog image resource.
    static let afterpayMark = ImageResource(name: "afterpay_mark", bundle: resourceBundle)

    /// The "apple_pay_mark" asset catalog image resource.
    static let applePayMark = ImageResource(name: "apple_pay_mark", bundle: resourceBundle)

    /// The "back_button" asset catalog image resource.
    static let backButton = ImageResource(name: "back_button", bundle: resourceBundle)

    /// The "bacsdd_logo" asset catalog image resource.
    static let bacsddLogo = ImageResource(name: "bacsdd_logo", bundle: resourceBundle)

    /// The "bank_icon_boa" asset catalog image resource.
    static let bankIconBoa = ImageResource(name: "bank_icon_boa", bundle: resourceBundle)

    /// The "bank_icon_capitalone" asset catalog image resource.
    static let bankIconCapitalone = ImageResource(name: "bank_icon_capitalone", bundle: resourceBundle)

    /// The "bank_icon_citibank" asset catalog image resource.
    static let bankIconCitibank = ImageResource(name: "bank_icon_citibank", bundle: resourceBundle)

    /// The "bank_icon_compass" asset catalog image resource.
    static let bankIconCompass = ImageResource(name: "bank_icon_compass", bundle: resourceBundle)

    /// The "bank_icon_default" asset catalog image resource.
    static let bankIconDefault = ImageResource(name: "bank_icon_default", bundle: resourceBundle)

    /// The "bank_icon_morganchase" asset catalog image resource.
    static let bankIconMorganchase = ImageResource(name: "bank_icon_morganchase", bundle: resourceBundle)

    /// The "bank_icon_nfcu" asset catalog image resource.
    static let bankIconNfcu = ImageResource(name: "bank_icon_nfcu", bundle: resourceBundle)

    /// The "bank_icon_pnc" asset catalog image resource.
    static let bankIconPnc = ImageResource(name: "bank_icon_pnc", bundle: resourceBundle)

    /// The "bank_icon_stripe" asset catalog image resource.
    static let bankIconStripe = ImageResource(name: "bank_icon_stripe", bundle: resourceBundle)

    /// The "bank_icon_suntrust" asset catalog image resource.
    static let bankIconSuntrust = ImageResource(name: "bank_icon_suntrust", bundle: resourceBundle)

    /// The "bank_icon_svb" asset catalog image resource.
    static let bankIconSvb = ImageResource(name: "bank_icon_svb", bundle: resourceBundle)

    /// The "bank_icon_td" asset catalog image resource.
    static let bankIconTd = ImageResource(name: "bank_icon_td", bundle: resourceBundle)

    /// The "bank_icon_usaa" asset catalog image resource.
    static let bankIconUsaa = ImageResource(name: "bank_icon_usaa", bundle: resourceBundle)

    /// The "bank_icon_usbank" asset catalog image resource.
    static let bankIconUsbank = ImageResource(name: "bank_icon_usbank", bundle: resourceBundle)

    /// The "bank_icon_wellsfargo" asset catalog image resource.
    static let bankIconWellsfargo = ImageResource(name: "bank_icon_wellsfargo", bundle: resourceBundle)

    /// The "carousel_applepay" asset catalog image resource.
    static let carouselApplepay = ImageResource(name: "carousel_applepay", bundle: resourceBundle)

    /// The "carousel_card_amex" asset catalog image resource.
    static let carouselCardAmex = ImageResource(name: "carousel_card_amex", bundle: resourceBundle)

    /// The "carousel_card_cartes_bancaires" asset catalog image resource.
    static let carouselCardCartesBancaires = ImageResource(name: "carousel_card_cartes_bancaires", bundle: resourceBundle)

    /// The "carousel_card_diners" asset catalog image resource.
    static let carouselCardDiners = ImageResource(name: "carousel_card_diners", bundle: resourceBundle)

    /// The "carousel_card_discover" asset catalog image resource.
    static let carouselCardDiscover = ImageResource(name: "carousel_card_discover", bundle: resourceBundle)

    /// The "carousel_card_jcb" asset catalog image resource.
    static let carouselCardJcb = ImageResource(name: "carousel_card_jcb", bundle: resourceBundle)

    /// The "carousel_card_mastercard" asset catalog image resource.
    static let carouselCardMastercard = ImageResource(name: "carousel_card_mastercard", bundle: resourceBundle)

    /// The "carousel_card_unionpay" asset catalog image resource.
    static let carouselCardUnionpay = ImageResource(name: "carousel_card_unionpay", bundle: resourceBundle)

    /// The "carousel_card_unknown" asset catalog image resource.
    static let carouselCardUnknown = ImageResource(name: "carousel_card_unknown", bundle: resourceBundle)

    /// The "carousel_card_visa" asset catalog image resource.
    static let carouselCardVisa = ImageResource(name: "carousel_card_visa", bundle: resourceBundle)

    /// The "carousel_sepa" asset catalog image resource.
    static let carouselSepa = ImageResource(name: "carousel_sepa", bundle: resourceBundle)

    /// The "cash_app_afterpay_mark" asset catalog image resource.
    static let cashAppAfterpayMark = ImageResource(name: "cash_app_afterpay_mark", bundle: resourceBundle)

    /// The "clearpay_mark" asset catalog image resource.
    static let clearpayMark = ImageResource(name: "clearpay_mark", bundle: resourceBundle)

    /// The "icon-pm-affirm" asset catalog image resource.
    static let iconPmAffirm = ImageResource(name: "icon-pm-affirm", bundle: resourceBundle)

    /// The "icon-pm-afterpay" asset catalog image resource.
    static let iconPmAfterpay = ImageResource(name: "icon-pm-afterpay", bundle: resourceBundle)

    /// The "icon-pm-alipay" asset catalog image resource.
    static let iconPmAlipay = ImageResource(name: "icon-pm-alipay", bundle: resourceBundle)

    /// The "icon-pm-aubecsdebit" asset catalog image resource.
    static let iconPmAubecsdebit = ImageResource(name: "icon-pm-aubecsdebit", bundle: resourceBundle)

    /// The "icon-pm-bancontact" asset catalog image resource.
    static let iconPmBancontact = ImageResource(name: "icon-pm-bancontact", bundle: resourceBundle)

    /// The "icon-pm-bank" asset catalog image resource.
    static let iconPmBank = ImageResource(name: "icon-pm-bank", bundle: resourceBundle)

    /// The "icon-pm-blik" asset catalog image resource.
    static let iconPmBlik = ImageResource(name: "icon-pm-blik", bundle: resourceBundle)

    /// The "icon-pm-boleto" asset catalog image resource.
    static let iconPmBoleto = ImageResource(name: "icon-pm-boleto", bundle: resourceBundle)

    /// The "icon-pm-card" asset catalog image resource.
    static let iconPmCard = ImageResource(name: "icon-pm-card", bundle: resourceBundle)

    /// The "icon-pm-cashapp" asset catalog image resource.
    static let iconPmCashapp = ImageResource(name: "icon-pm-cashapp", bundle: resourceBundle)

    /// The "icon-pm-eps" asset catalog image resource.
    static let iconPmEps = ImageResource(name: "icon-pm-eps", bundle: resourceBundle)

    /// The "icon-pm-giropay" asset catalog image resource.
    static let iconPmGiropay = ImageResource(name: "icon-pm-giropay", bundle: resourceBundle)

    /// The "icon-pm-ideal" asset catalog image resource.
    static let iconPmIdeal = ImageResource(name: "icon-pm-ideal", bundle: resourceBundle)

    /// The "icon-pm-klarna" asset catalog image resource.
    static let iconPmKlarna = ImageResource(name: "icon-pm-klarna", bundle: resourceBundle)

    /// The "icon-pm-konbini" asset catalog image resource.
    static let iconPmKonbini = ImageResource(name: "icon-pm-konbini", bundle: resourceBundle)

    /// The "icon-pm-oxxo" asset catalog image resource.
    static let iconPmOxxo = ImageResource(name: "icon-pm-oxxo", bundle: resourceBundle)

    /// The "icon-pm-p24" asset catalog image resource.
    static let iconPmP24 = ImageResource(name: "icon-pm-p24", bundle: resourceBundle)

    /// The "icon-pm-paypal" asset catalog image resource.
    static let iconPmPaypal = ImageResource(name: "icon-pm-paypal", bundle: resourceBundle)

    /// The "icon-pm-revolutpay" asset catalog image resource.
    static let iconPmRevolutpay = ImageResource(name: "icon-pm-revolutpay", bundle: resourceBundle)

    /// The "icon-pm-sepa" asset catalog image resource.
    static let iconPmSepa = ImageResource(name: "icon-pm-sepa", bundle: resourceBundle)

    /// The "icon-pm-swish" asset catalog image resource.
    static let iconPmSwish = ImageResource(name: "icon-pm-swish", bundle: resourceBundle)

    /// The "icon-pm-upi" asset catalog image resource.
    static let iconPmUpi = ImageResource(name: "icon-pm-upi", bundle: resourceBundle)

    /// The "icon_cancel" asset catalog image resource.
    static let iconCancel = ImageResource(name: "icon_cancel", bundle: resourceBundle)

    /// The "icon_check" asset catalog image resource.
    static let iconCheck = ImageResource(name: "icon_check", bundle: resourceBundle)

    /// The "icon_checkmark" asset catalog image resource.
    static let iconCheckmark = ImageResource(name: "icon_checkmark", bundle: resourceBundle)

    /// The "icon_chevron_left" asset catalog image resource.
    static let iconChevronLeft = ImageResource(name: "icon_chevron_left", bundle: resourceBundle)

    /// The "icon_chevron_left_standalone" asset catalog image resource.
    static let iconChevronLeftStandalone = ImageResource(name: "icon_chevron_left_standalone", bundle: resourceBundle)

    /// The "icon_chevron_right" asset catalog image resource.
    static let iconChevronRight = ImageResource(name: "icon_chevron_right", bundle: resourceBundle)

    /// The "icon_edit" asset catalog image resource.
    static let iconEdit = ImageResource(name: "icon_edit", bundle: resourceBundle)

    /// The "icon_link_error" asset catalog image resource.
    static let iconLinkError = ImageResource(name: "icon_link_error", bundle: resourceBundle)

    /// The "icon_link_success" asset catalog image resource.
    static let iconLinkSuccess = ImageResource(name: "icon_link_success", bundle: resourceBundle)

    /// The "icon_lock" asset catalog image resource.
    static let iconLock = ImageResource(name: "icon_lock", bundle: resourceBundle)

    /// The "icon_menu" asset catalog image resource.
    static let iconMenu = ImageResource(name: "icon_menu", bundle: resourceBundle)

    /// The "icon_menu_horizontal" asset catalog image resource.
    static let iconMenuHorizontal = ImageResource(name: "icon_menu_horizontal", bundle: resourceBundle)

    /// The "icon_plus" asset catalog image resource.
    static let iconPlus = ImageResource(name: "icon_plus", bundle: resourceBundle)

    /// The "icon_x" asset catalog image resource.
    static let iconX = ImageResource(name: "icon_x", bundle: resourceBundle)

    /// The "icon_x_standalone" asset catalog image resource.
    static let iconXStandalone = ImageResource(name: "icon_x_standalone", bundle: resourceBundle)

    /// The "link_icon" asset catalog image resource.
    static let linkIcon = ImageResource(name: "link_icon", bundle: resourceBundle)

    /// The "link_logo" asset catalog image resource.
    static let linkLogo = ImageResource(name: "link_logo", bundle: resourceBundle)

    /// The "link_logo_bw" asset catalog image resource.
    static let linkLogoBw = ImageResource(name: "link_logo_bw", bundle: resourceBundle)

    /// The "link_logo_knockout" asset catalog image resource.
    static let linkLogoKnockout = ImageResource(name: "link_logo_knockout", bundle: resourceBundle)

    /// The "polling_error_icon" asset catalog image resource.
    static let pollingErrorIcon = ImageResource(name: "polling_error_icon", bundle: resourceBundle)

}

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif