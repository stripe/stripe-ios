//
//  SpinnerView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/9/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SpinnerView: UIView {

    private let appearance: FinancialConnectionsAppearance?
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: Image.spinner.makeImage(template: true))
        // Fallback to a neutral spinner color if the appearance hasn't been loaded yet.
        // This should only be the case for the initial spinner that is shown.
        imageView.tintColor = appearance?.colors.spinner ?? FinancialConnectionsAppearance.Colors.spinnerNeutral
        return imageView
    }()
    private let animationKey = "animation_key"

    init(appearance: FinancialConnectionsAppearance?, shouldStartAnimating: Bool = true) {
        self.appearance = appearance
        super.init(frame: .zero)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        if shouldStartAnimating {
            startAnimating()
        }
    }

    func startAnimating() {
        let rotatingAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotatingAnimation.byValue = 2 * Float.pi
        rotatingAnimation.duration = 0.7
        rotatingAnimation.isAdditive = true
        rotatingAnimation.repeatCount = .infinity
        imageView.layer.add(rotatingAnimation, forKey: animationKey)
    }

    func stopAnimating() {
        imageView.layer.removeAnimation(forKey: animationKey)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

private struct SpinnerViewUIViewRepresentable: UIViewRepresentable {
    let appearance: FinancialConnectionsAppearance?

    func makeUIView(context: Context) -> SpinnerView {
        SpinnerView(appearance: appearance)
    }

    func updateUIView(_ uiView: SpinnerView, context: Context) {}
}

struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SpinnerViewUIViewRepresentable(appearance: .stripe)
            SpinnerViewUIViewRepresentable(appearance: .link)
            SpinnerViewUIViewRepresentable(appearance: nil)
        }
    }
}

#endif
