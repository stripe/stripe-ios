//
//  DynamicImageView+Unknown.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 9/21/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeUICore

@_spi(InternalOnlyAPI) public extension DynamicImageView {
    static func makeUnknownCardImageView(theme: ElementsAppearance) -> DynamicImageView {
        return DynamicImageView(
            dynamicImage: STPImageLibrary.unknownCardCardImage(),
            pairedColor: theme.colors.componentBackground
        )
    }
}
