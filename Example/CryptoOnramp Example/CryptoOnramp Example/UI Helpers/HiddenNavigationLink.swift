//
//  HiddenNavigationLink.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI

/// A hidden NavigationLink that can be triggered programmatically via a binding.
struct HiddenNavigationLink<Destination: View>: View {
    /// The destination view to show when the `isActive` binding is `true`.
    let destination: Destination

    /// Determines whether to show `destination`.
    @Binding var isActive: Bool

    // MARK: - View

    var body: some View {
        NavigationLink(destination: destination, isActive: $isActive) {
            EmptyView()
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }
}
