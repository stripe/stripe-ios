//
//  Images.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore

// TODO(yuki|https://jira.corp.stripe.com/browse/MOBILESDK-309): Refactor STPImageLibrary's images to live here as well

/// The canonical set of all image files in the SDK.
/// This helps us avoid duplicates and automatically test that all images load properly
/// Raw value is the image file name. We use snake case to make long names easier to read.
enum Image: String, CaseIterable, ImageMaker {
    typealias BundleLocator = StripePaymentSheetBundleLocator

    /// https://developer.apple.com/apple-pay/marketing/
    case apple_pay_mark = "apple_pay_mark"

    // Payment Method Type images
    case pm_type_affirm = "icon-pm-affirm"
    case pm_type_afterpay = "icon-pm-afterpay"
    case pm_type_aubecsdebit = "icon-pm-aubecsdebit"
    case pm_type_us_bank = "icon-pm-bank"
    case pm_type_bancontact = "icon-pm-bancontact"
    case pm_type_card = "icon-pm-card"
    case pm_type_eps = "icon-pm-eps"
    case pm_type_giropay = "icon-pm-giropay"
    case pm_type_ideal = "icon-pm-ideal"
    case pm_type_klarna = "icon-pm-klarna"
    case pm_type_p24 = "icon-pm-p24"
    case pm_type_sepa = "icon-pm-sepa"
    case pm_type_paypal = "icon-pm-paypal"
    case pm_type_link = "icon-pm-link"
    case pm_type_upi = "icon-pm-upi"
    case pm_type_cashapp = "icon-pm-cashapp"
    case pm_type_revolutpay = "icon-pm-revolutpay"
    case pm_type_blik = "icon-pm-blik"
    case pm_type_alipay = "icon-pm-alipay"
    case pm_type_oxxo = "icon-pm-oxxo"
    case pm_type_konbini = "icon-pm-konbini"
    case pm_type_boleto = "icon-pm-boleto"
    case pm_type_swish = "icon-pm-swish"

    // Icons/symbols
    case icon_checkmark = "icon_checkmark"
    case icon_chevron_left = "icon_chevron_left"
    case icon_lock = "icon_lock"
    case icon_plus = "icon_plus"
    case icon_x = "icon_x"
    case icon_x_standalone = "icon_x_standalone"
    case icon_chevron_left_standalone = "icon_chevron_left_standalone"
    case icon_edit = "icon_edit"

    // Link
    case link_logo = "link_logo"
    case link_arrow = "link_arrow"

    // Carousel
    case carousel_applepay
    case carousel_card_amex
    case carousel_card_cartes_bancaires
    case carousel_card_diners
    case carousel_card_discover
    case carousel_card_jcb
    case carousel_card_mastercard
    case carousel_card_unionpay
    case carousel_card_unknown
    case carousel_card_visa
    case carousel_link
    case carousel_sepa

    // Affirm Images
    case affirm_copy = "affirm_mark"

    // Polling / UPI
    case polling_error = "polling_error_icon"

    // Mandates
    case bacsdd_logo = "bacsdd_logo"
}
