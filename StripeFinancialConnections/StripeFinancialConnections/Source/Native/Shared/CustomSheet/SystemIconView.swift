//
//  SystemIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/6/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class SystemIconView: UIView {

    enum Style {
        case circle
        case square
    }

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        return iconImageView
    }()

    init(style: Style = .circle, image: Image? = nil) {
        super.init(frame: .zero)
        let diameter: CGFloat = 56
        let cornerRadius: CGFloat
        switch style {
        case .circle:
            cornerRadius = diameter / 2
        case .square:
            cornerRadius = 12
        }

        backgroundColor = .brand100.withAlphaComponent(0.5) // TODO(kgaidis): change color
        layer.cornerRadius = cornerRadius
        clipsToBounds = true

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
        ])

        addSubview(iconImageView)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        if let image = image {
            setImage(image)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: Image) {
        iconImageView.image = image
            .makeImage()
            .withTintColor(
                .textBrand, // TODO(kgaidis): change color
                renderingMode: .alwaysOriginal
            )
    }

    func setImageUrl(_ imageUrl: String?) {
        iconImageView.setImage(
            with: imageUrl,
            placeholder: Image.brandicon_default.makeImage() // TODO(kgaidis): change color
        )
    }
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct SystemIconViewUIViewRepresentable: UIViewRepresentable {

    let style: SystemIconView.Style
    let image: Image

    func makeUIView(context: Context) -> SystemIconView {
        SystemIconView(
            style: style,
            image: image
        )
    }

    func updateUIView(_ systemIconView: SystemIconView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct SystemIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VStack(spacing: 10) {
                SystemIconViewUIViewRepresentable(
                    style: .circle,
                    image: .check
                )

                SystemIconViewUIViewRepresentable(
                    style: .square,
                    image: .panel_arrow_right
                )

                Spacer()
            }
            .frame(width: 100, height: 200)
            .padding()

            Spacer()
        }
    }
}

#endif
