//
//  FoldAvoidingScrollView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/21/26.
//

import SwiftUI

/// Keeps a group of custom controls in one usable region, with scrolling when height is limited.
struct FoldAvoidingScrollView<Content: View>: View {

    /// The content alignment within the usable region. Defaults to `.center`.
    var alignment: Alignment = .center

    /// The content to display and scroll within the usable region.
    @ViewBuilder var content: Content

    // MARK: - View

    var body: some View {
        GeometryReader { geometry in
            let insets = geometry.activeFoldInsets()

            ScrollView {
                content
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: max(0, geometry.size.height - insets.top - insets.bottom), alignment: alignment)
            }
            .frame(
                width: max(0, geometry.size.width - insets.leading - insets.trailing),
                height: max(0, geometry.size.height - insets.top - insets.bottom)
            )
            .padding(insets)
        }
    }
}
