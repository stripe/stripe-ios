//
//  CSSHelpers.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/9/24.
//

import UIKit

extension CGFloat {
    var pxString: String {
        "\(Int(self))px"
    }
}

extension UIFont.Weight {
    var cssValue: String? {
        // https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight#common_weight_name_mapping
        switch self {
        case .thin: return "100"
        case .ultraLight: return "200"
        case .light: return "300"
        case .regular: return "400"
        case .medium: return "500"
        case .semibold: return "600"
        case .bold: return "700"
        case .heavy: return "800"
        case .black: return "900"
        default: return nil
        }
    }
}
