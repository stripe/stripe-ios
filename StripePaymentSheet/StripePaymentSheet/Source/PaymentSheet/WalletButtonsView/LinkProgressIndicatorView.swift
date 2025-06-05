//
//  LinkProgressIndicatorView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

import SwiftUI

@available(iOS 16.0, *)
struct LinkProgressIndicatorView: View {
    private static let size: CGFloat = 20.0

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 3))
                .frame(width: Self.size, height: Self.size)
                .foregroundColor(Color(uiColor: LinkUI.appearance.colors.primary))
                .opacity(0.1)

            Circle()
                .trim(from: 0.0, to: 0.2)
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: Self.size, height: Self.size)
                .foregroundColor(Color(uiColor: LinkUI.appearance.colors.primary))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    LinkProgressIndicatorView()
}
