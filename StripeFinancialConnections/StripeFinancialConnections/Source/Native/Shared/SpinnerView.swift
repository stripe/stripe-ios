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

    private let imageView = UIImageView(image: Image.spinner.makeImage())
    private let animationKey = "animation_key"

    init(shouldStartAnimating: Bool = true) {
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

    func makeUIView(context: Context) -> SpinnerView {
        SpinnerView()
    }

    func updateUIView(_ uiView: SpinnerView, context: Context) {}
}

struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        SpinnerViewUIViewRepresentable()
    }
}

#endif
