//
//  STPColorUtils.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

class STPColorUtils: NSObject {
    class func perceivedBrightness(for color: UIColor?) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        if color?.getRed(&red, green: &green, blue: &blue, alpha: nil) ?? false {
            // We're using the luma value from YIQ
            // https://en.wikipedia.org/wiki/YIQ#From_RGB_to_YIQ
            // recommended by https://www.w3.org/WAI/ER/WD-AERT/#color-contrast
            return red * CGFloat(0.299) + green * CGFloat(0.587) + blue * CGFloat(0.114)
        } else {
            // Couldn't get RGB for this color, device couldn't convert it from whatever
            // colorspace it's in.
            // Make it "bright", since most of the color space is (based on our current
            // formula), but not very bright.
            return CGFloat(0.4)
        }
    }

    class func brighterColor(_ color1: UIColor?, color2: UIColor?) -> UIColor? {
        let brightness1 = self.perceivedBrightness(for: color1)
        let brightness2 = self.perceivedBrightness(for: color2)
        return brightness1 >= brightness2 ? color1 : color2
    }

    class func colorIsBright(_ color: UIColor?) -> Bool {
        return self.perceivedBrightness(for: color) > 0.3
    }
}
