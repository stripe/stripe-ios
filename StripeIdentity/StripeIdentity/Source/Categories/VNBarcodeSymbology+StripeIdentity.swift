//
//  VNBarcodeSymbology+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/14/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import Vision

extension VNBarcodeSymbology {
    /// Initializes a barcode symbology from a string value.
    ///
    /// - Parameters:
    ///   - string: A case-insensitive string value of the symbology.
    ///
    /// - Returns: A matching symbology or nil if no matching symbology exists.
    init?(
        fromStringValue string: String
    ) {
        switch string.lowercased() {
        case "aztec":
            self = .aztec
        case "codabar":
            self = .codabar
        case "code39":
            self = .code39
        case "code39checksum":
            self = .code39Checksum
        case "code39fullascii":
            self = .code39FullASCII
        case "code39fullasciichecksum":
            self = .code39FullASCIIChecksum
        case "code93":
            self = .code93
        case "code93i":
            self = .code93i
        case "code128":
            self = .code128
        case "datamatrix":
            self = .dataMatrix
        case "ean8":
            self = .ean8
        case "ean13":
            self = .ean13
        case "gs1databar":
            self = .gs1DataBar
        case "gs1databarexpanded":
            self = .gs1DataBarExpanded
        case "gs1databarlimited":
            self = .gs1DataBarLimited
        case "i2of5":
            self = .i2of5
        case "i2of5checksum":
            self = .i2of5Checksum
        case "itf14":
            self = .itf14
        case "micropdf417":
            self = .microPDF417
        case "microqr":
            self = .microQR
        case "pdf417":
            self = .pdf417
        case "qr":
            self = .qr
        case "upce":
            self = .upce
        default:
            return nil
        }
    }

    /// Returns string representation of the symbology
    var stringValue: String {
        switch self {
        case .codabar:
            return "codabar"
        case .gs1DataBar:
            return "gs1DataBar"
        case .gs1DataBarExpanded:
            return "gs1DataBarExpanded"
        case .gs1DataBarLimited:
            return "gs1DataBarLimited"
        case .microPDF417:
            return "microPDF417"
        case .microQR:
            return "microQR"
        case .aztec:
            return "aztec"
        case .code39:
            return "code39"
        case .code39Checksum:
            return "code39Checksum"
        case .code39FullASCII:
            return "code39FullASCII"
        case .code39FullASCIIChecksum:
            return "code39FullASCIIChecksum"
        case .code93:
            return "code93"
        case .code93i:
            return "code93i"
        case .code128:
            return "code128"
        case .dataMatrix:
            return "dataMatrix"
        case .ean8:
            return "ean8"
        case .ean13:
            return "ean13"
        case .i2of5:
            return "i2of5"
        case .i2of5Checksum:
            return "i2of5Checksum"
        case .itf14:
            return "itf14"
        case .pdf417:
            return "pdf417"
        case .qr:
            return "qr"
        case .upce:
            return "upce"
        default:
            return self.rawValue
        }
    }
}
