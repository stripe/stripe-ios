//
// BackwardsCompatibleColors.swift
//
// This file is adapted from https://github.com/noahsark769/ColorCompatibility
// Thank you Noah Gilmore!
// Copyright (c) 2019 Noah Gilmore <noah.w.gilmore@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

enum CompatibleColor {
    static var label: UIColor {
        if #available(iOS 13, *) {
            return .label
        }
        return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
    static var secondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }
        return UIColor(
            red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157,
            alpha: 0.6)
    }
    static var tertiaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .tertiaryLabel
        }
        return UIColor(
            red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157,
            alpha: 0.3)
    }
    static var quaternaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .quaternaryLabel
        }
        return UIColor(
            red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157,
            alpha: 0.18)
    }
    static var systemFill: UIColor {
        if #available(iOS 13, *) {
            return .systemFill
        }
        return UIColor(
            red: 0.47058823529411764, green: 0.47058823529411764, blue: 0.5019607843137255,
            alpha: 0.2)
    }
    static var secondarySystemFill: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemFill
        }
        return UIColor(
            red: 0.47058823529411764, green: 0.47058823529411764, blue: 0.5019607843137255,
            alpha: 0.16)
    }
    static var tertiarySystemFill: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemFill
        }
        return UIColor(
            red: 0.4627450980392157, green: 0.4627450980392157, blue: 0.5019607843137255,
            alpha: 0.12)
    }
    static var quaternarySystemFill: UIColor {
        if #available(iOS 13, *) {
            return .quaternarySystemFill
        }
        return UIColor(
            red: 0.4549019607843137, green: 0.4549019607843137, blue: 0.5019607843137255,
            alpha: 0.08)
    }
    static var placeholderText: UIColor {
        if #available(iOS 13, *) {
            return .placeholderText
        }
        return UIColor(
            red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157,
            alpha: 0.3)
    }
    static var systemBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemBackground
        }
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    static var secondarySystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemBackground
        }
        return UIColor(
            red: 0.9490196078431372, green: 0.9490196078431372, blue: 0.9686274509803922, alpha: 1.0
        )
    }
    static var tertiarySystemBackground: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemBackground
        }
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    static var systemGroupedBackground: UIColor {
        if #available(iOS 13, *) {
            return .systemGroupedBackground
        }
        return UIColor(
            red: 0.9490196078431372, green: 0.9490196078431372, blue: 0.9686274509803922, alpha: 1.0
        )
    }
    static var secondarySystemGroupedBackground: UIColor {
        if #available(iOS 13, *) {
            return .secondarySystemGroupedBackground
        }
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    static var tertiarySystemGroupedBackground: UIColor {
        if #available(iOS 13, *) {
            return .tertiarySystemGroupedBackground
        }
        return UIColor(
            red: 0.9490196078431372, green: 0.9490196078431372, blue: 0.9686274509803922, alpha: 1.0
        )
    }
    static var separator: UIColor {
        if #available(iOS 13, *) {
            return .separator
        }
        return UIColor(
            red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157,
            alpha: 0.29)
    }
    static var opaqueSeparator: UIColor {
        if #available(iOS 13, *) {
            return .opaqueSeparator
        }
        return UIColor(
            red: 0.7764705882352941, green: 0.7764705882352941, blue: 0.7843137254901961, alpha: 1.0
        )
    }
    static var link: UIColor {
        if #available(iOS 13, *) {
            return .link
        }
        return UIColor(red: 0.0, green: 0.47843137254901963, blue: 1.0, alpha: 1.0)
    }
    static var systemIndigo: UIColor {
        if #available(iOS 13, *) {
            return .systemIndigo
        }
        return UIColor(
            red: 0.34509803921568627, green: 0.33725490196078434, blue: 0.8392156862745098,
            alpha: 1.0)
    }
    static var systemGray2: UIColor {
        if #available(iOS 13, *) {
            return .systemGray2
        }
        return UIColor(
            red: 0.6823529411764706, green: 0.6823529411764706, blue: 0.6980392156862745, alpha: 1.0
        )
    }
    static var systemGray3: UIColor {
        if #available(iOS 13, *) {
            return .systemGray3
        }
        return UIColor(red: 0.7803921568627451, green: 0.7803921568627451, blue: 0.8, alpha: 1.0)
    }
    static var systemGray4: UIColor {
        if #available(iOS 13, *) {
            return .systemGray4
        }
        return UIColor(
            red: 0.8196078431372549, green: 0.8196078431372549, blue: 0.8392156862745098, alpha: 1.0
        )
    }
    static var systemGray5: UIColor {
        if #available(iOS 13, *) {
            return .systemGray5
        }
        return UIColor(
            red: 0.8980392156862745, green: 0.8980392156862745, blue: 0.9176470588235294, alpha: 1.0
        )
    }
    static var systemGray6: UIColor {
        if #available(iOS 13, *) {
            return .systemGray6
        }
        return UIColor(
            red: 0.9490196078431372, green: 0.9490196078431372, blue: 0.9686274509803922, alpha: 1.0
        )
    }
}
