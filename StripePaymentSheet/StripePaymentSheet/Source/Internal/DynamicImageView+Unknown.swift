//
//  DynamicImageView+Unknown.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/21/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeUICore

extension DynamicImageView {
    static func makeUnknownCardImageView(theme: ElementsAppearance) -> DynamicImageView {
        return DynamicImageView(
            dynamicImage: PaymentSheetImageLibrary.unknownCardCardImage(),
            pairedColor: theme.colors.componentBackground
        )
    }
}
