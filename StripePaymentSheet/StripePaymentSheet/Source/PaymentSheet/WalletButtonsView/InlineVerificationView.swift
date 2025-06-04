//
//  InlineVerificationView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/4/25.
//

import SwiftUI

@available(iOS 16.0, *)
struct InlineVerificationView: View {
    let email: String
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Email")
                    .font(.body)
                    .foregroundColor(Color(uiColor: .linkTextBrand))

                Spacer(minLength: 22.0)

                ShimmerEffect(color: Color(uiColor: .linkTextBrand)) { gradient in
                    Text(email)
                        .font(.headline)
                        .foregroundStyle(gradient)
                }

                Button(action: onDismiss) {
                    SwiftUI.Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(uiColor: .linkBrandBackground))
            .frame(height: 56)

            Rectangle()
                .fill(Color(uiColor: .linkBorderDefault))
                .frame(height: 0.5)

            OneTimeCodeView(onResend: {})
                .tint(Color(uiColor: .linkBorderSelected))
                .padding(.vertical, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22.0))
        .overlay(
            RoundedRectangle(cornerRadius: 22.0)
                .stroke(Color(uiColor: .linkBorderDefault), lineWidth: 0.5)
        )
    }
}

@available(iOS 16.0, *)
struct ShimmerEffect<Content: View>: View {
    let color: Color
    let content: (LinearGradient) -> Content

    @State private var phase: CGFloat = -1
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let itemWidth = geometry.size.width
            let shimmerWidth = itemWidth * 0.3

            let gradient: [Color] = [
                color,
                color.opacity(0.4),
                color,
            ]

            let linearGradient = LinearGradient(
                gradient: Gradient(colors: gradient),
                startPoint: UnitPoint(
                    x: phase - shimmerWidth / itemWidth,
                    y: 0
                ),
                endPoint: UnitPoint(
                    x: phase + shimmerWidth / itemWidth,
                    y: 0
                )
            )

            VStack(alignment: .leading) {
                Spacer(minLength: 0)

                content(linearGradient)
                    .onAppear {
                        animationTask = runAnimation()
                    }
                    .onDisappear {
                        animationTask?.cancel()
                        animationTask = nil
                    }

                Spacer(minLength: 0)
            }
        }
    }

    private func runAnimation() -> Task<Void, Never> {
        Task { @MainActor in
            let duration: TimeInterval = 3
            let delay: TimeInterval = 0.5

            while !Task.isCancelled {
                let animation = Animation
                    .linear(duration: duration)
                    .delay(delay)

                withAnimation(animation) {
                    // Animate the shimmer across
                    phase = 2
                }

                try? await Task.sleep(for: .seconds(duration + delay))
                if Task.isCancelled {
                    break
                }

                // Reset to the beginning
                phase = -1
            }
        }
    }
}

@available(iOS 16.0, *)
struct InlineVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        InlineVerificationView(
            email: "mats@stripe.com",
            onDismiss: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
