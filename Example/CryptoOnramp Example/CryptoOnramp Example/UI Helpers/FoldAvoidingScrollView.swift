//
//  FoldAvoidingScrollView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

/// Keeps a group of custom controls in one usable region, with scrolling when height is limited.
struct FoldAvoidingScrollView<Content: View>: View {
    private let alignment: Alignment
    private let prefersLargerRegion: Bool
    private let content: (CGFloat) -> Content

    @State private var insets = EdgeInsets()

    /// Creates a scroll view whose content can adapt to the usable height.
    /// - Parameters:
    ///   - alignment: The content alignment within the usable region. Defaults to `.center`.
    ///   - prefersLargerRegion: Use the side of a horizontal fold with more available height. When `false`, always use the space below the fold. Defaults to `false`.
    ///   - content: The content to display, given the usable height after fold avoidance and safe areas.
    init(
        alignment: Alignment = .center,
        prefersLargerRegion: Bool = false,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) {
        self.alignment = alignment
        self.prefersLargerRegion = prefersLargerRegion
        self.content = content
    }

    // MARK: - View

    var body: some View {
        GeometryReader { geometry in
            let width = max(0, geometry.size.width - insets.leading - insets.trailing)
            let height = max(0, geometry.size.height - insets.top - insets.bottom)

            ScrollView {
                content(height)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: height, alignment: alignment)
            }
            .frame(width: width, height: height)
            .padding(insets)
        }
        // Measure the full container so moving the content doesn't change the fold-avoidance calculation.
        .onGeometryChange(for: EdgeInsets.self) { geometry in
            let lowerRegionInsets = geometry.activeFoldInsets()
            guard prefersLargerRegion else { return lowerRegionInsets }

            // The keyboard can leave more usable space above a horizontal fold.
            let upperRegionInsets = geometry.activeFoldInsets(anchoredToBottom: true)
            let lowerRegionHeight = geometry.size.height - lowerRegionInsets.top - lowerRegionInsets.bottom
            let upperRegionHeight = geometry.size.height - upperRegionInsets.top - upperRegionInsets.bottom
            return upperRegionHeight > lowerRegionHeight ? upperRegionInsets : lowerRegionInsets
        } action: { insets in
            self.insets = insets
        }
    }
}
