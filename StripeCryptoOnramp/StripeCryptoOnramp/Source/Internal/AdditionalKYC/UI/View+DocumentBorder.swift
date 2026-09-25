//
//  View+DocumentBorder.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/24/26.
//

import SwiftUI

extension View {

    /// Overlays the dashed, rounded border used by document upload controls.
    /// - Parameter isVisible: Whether to show the border.
    func dashedDocumentBorderOverlay(isVisible: Bool = true) -> some View {
        overlay {
            if isVisible {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.documentBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
    }
}
