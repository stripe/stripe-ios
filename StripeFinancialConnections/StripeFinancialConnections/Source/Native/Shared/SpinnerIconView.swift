//
//  SpinnerIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SpinnerIconView: UIView {

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.backgroundColor = .clear
        let image = Image.spinner.makeImage()
        iconImageView.image = image
        return iconImageView
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
        addAndPinSubview(iconImageView)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),
        ])

        startRotating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopRotating()
    }

    private func startRotating() {
        let animationKey = "transform.rotation.z"
        let animation = CABasicAnimation(keyPath: animationKey)
        animation.toValue = NSNumber(value: .pi * 2.0)
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.isCumulative = true
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: animationKey)
    }

    private func stopRotating() {
        layer.removeAllAnimations()
    }
}

#if DEBUG

import SwiftUI

private struct SpinnerIconViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> SpinnerIconView {
        SpinnerIconView()
    }

    func updateUIView(_ uiView: SpinnerIconView, context: Context) {}
}

struct SpinnerIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SpinnerIconViewUIViewRepresentable()
                .frame(width: 40, height: 40)
            Spacer()
        }
        .padding()
    }
}

#endif
