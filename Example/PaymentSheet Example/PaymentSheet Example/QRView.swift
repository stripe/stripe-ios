//
//  QRView.swift
//  PaymentSheet Example
//
//  Created by David Estes on 9/14/23.
//

import Foundation
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QRView: View {
    let url: URL
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    private func generateQRCode() -> UIImage {
        filter.message = Data(url.absoluteString.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        Image(uiImage: generateQRCode())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
