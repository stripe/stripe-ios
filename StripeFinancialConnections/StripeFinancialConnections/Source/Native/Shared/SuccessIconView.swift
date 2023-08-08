//
//  SuccessIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/14/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SuccessIconView: UIView {

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        let image = Image.check.makeImage()
            .withTintColor(.white)
        iconImageView.image = image
        return iconImageView
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.textSuccess
        addSubview(iconImageView)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.sizeToFit()
        iconImageView.center = CGPoint(
            x: bounds.midX,
            y: bounds.midY
        )

        layer.cornerRadius = bounds.size.width / 2.0
    }
}

#if DEBUG

import SwiftUI

private struct SuccessIconViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> SuccessIconView {
        SuccessIconView()
    }

    func updateUIView(_ uiView: SuccessIconView, context: Context) {}
}

struct SuccessIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SuccessIconViewUIViewRepresentable()
                .frame(width: 40, height: 40)
            Spacer()
        }
        .padding()
    }
}

#endif
