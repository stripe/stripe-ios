//
//  Color.swift
//  Standard Integration
//
//  Created by Yuki Tokuhiro on 5/31/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

extension UIColor {
    static let stripeBrightGreen : UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0) :
                    UIColor(red: 39/255, green: 213/255, blue: 149/255, alpha: 1.0)
            })
        } else {
            return UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0)
        }
    }()
    static let stripeDarkBlue : UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0) :
                    UIColor(red: 121/255, green: 142/255, blue: 188/255, alpha: 1.0)
            })
        } else {
            return UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0)
        }
    }()
}
