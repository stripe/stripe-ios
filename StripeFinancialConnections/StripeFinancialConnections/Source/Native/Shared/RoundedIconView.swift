//
//  RoundedIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/29/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class RoundedIconView: UIView {

    enum ImageType {
        case image(Image)
        case imageUrl(String?)
    }

    enum Style {
        case rounded
        case circle
    }

    init(image: ImageType, style: Style) {
        super.init(frame: .zero)
        let diameter: CGFloat = 56
        let cornerRadius: CGFloat
        switch style {
        case .rounded:
            cornerRadius = 12
        case .circle:
            cornerRadius = diameter / 2
        }

        backgroundColor = .brand25
        layer.cornerRadius = cornerRadius

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
        ])

        let iconImageView = UIImageView()
        iconImageView.tintColor = .iconActionPrimary
        switch image {
        case .image(let image):
            iconImageView.image = image.makeImage(template: true)
        case .imageUrl(let imageUrl):
            iconImageView.setImage(
                with: imageUrl,
                placeholder: nil,
                useAlwaysTemplateRenderingMode: true
            )
        }
        addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

private struct RoundedIconViewUIViewRepresentable: UIViewRepresentable {

    let image: Image
    let style: RoundedIconView.Style

    func makeUIView(context: Context) -> RoundedIconView {
        RoundedIconView(
            image: .image(image),
            style: style
        )
    }

    func updateUIView(_ institutionIconView: RoundedIconView, context: Context) {}
}

struct RoundedIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VStack(spacing: 20) {
                Spacer().frame(height: 30)

                RoundedIconViewUIViewRepresentable(
                    image: .search,
                    style: .rounded
                )
                .frame(width: 56, height: 56)

                RoundedIconViewUIViewRepresentable(
                    image: .cancel_circle,
                    style: .circle
                )
                .frame(width: 56, height: 56)

                Spacer()
            }
            Spacer()
        }
    }
}

#endif
