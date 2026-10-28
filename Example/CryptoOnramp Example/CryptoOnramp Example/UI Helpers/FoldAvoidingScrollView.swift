//
//  FoldAvoidingScrollView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

/// Scrolls content beside vertical folds, with optional horizontal-fold avoidance.
struct FoldAvoidingScrollView<Content: View>: View {
    private let alignment: Alignment
    private let avoidsHorizontalFolds: Bool
    private let prefersLargerRegion: Bool
    private let content: (CGFloat) -> Content

    @State private var insets = EdgeInsets()

    /// Creates a scroll view whose content can adapt to the usable height.
    /// - Parameters:
    ///   - alignment: The content alignment within the usable region. Defaults to `.center`.
    ///   - avoidsHorizontalFolds: Whether to keep content on one side of a horizontal fold. Set to `false` to scroll across it while still avoiding vertical folds. Defaults to `true`.
    ///   - prefersLargerRegion: When avoiding horizontal folds, use the side with more available height. When `false`, use the space below the fold. Defaults to `false`.
    ///   - content: The content to display, given the usable height after fold avoidance and safe areas.
    init(
        alignment: Alignment = .center,
        avoidsHorizontalFolds: Bool = true,
        prefersLargerRegion: Bool = false,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) {
        self.alignment = alignment
        self.avoidsHorizontalFolds = avoidsHorizontalFolds
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
            var lowerRegionInsets = geometry.activeFoldInsets()

            if !avoidsHorizontalFolds {
                lowerRegionInsets.top = 0
                lowerRegionInsets.bottom = 0
                return lowerRegionInsets
            }

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
