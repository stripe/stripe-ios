//
//  InstitutionIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/27/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionIconView: UIView {

    enum Size {
        case small  // 24x24
        case medium  // 36x36
        case large  // 40x40
    }

    private lazy var institutionImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
    }()
    private lazy var warningIconView: UIView = {
        return CreateWarningIconView()
    }()

    init(size: Size, showWarning: Bool = false) {
        super.init(frame: .zero)
        let diameter: CGFloat
        let cornerRadius: CGFloat
        switch size {
        case .small:
            diameter = 24
            cornerRadius = 4
        case .medium:
            diameter = 36
            cornerRadius = 4
        case .large:
            diameter = 40
            cornerRadius = 6
        }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
        ])

        addAndPinSubview(institutionImageView)
        institutionImageView.layer.cornerRadius = cornerRadius
        institutionImageView.clipsToBounds = true

        if showWarning {
            addSubview(warningIconView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        warningIconView.center = CGPoint(x: bounds.width, y: 0)
    }

    func setImageUrl(_ imageUrl: String?) {
        institutionImageView.setImage(
            with: imageUrl,
            placeholder: Image.brandicon_default.makeImage()
        )
    }
}

private func CreateWarningIconView() -> UIView {
    let diameter: CGFloat = 20

    let circleContainerView = UIView()
    circleContainerView.backgroundColor = UIColor.customBackgroundColor
    circleContainerView.layer.cornerRadius = diameter / 2
    circleContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        circleContainerView.widthAnchor.constraint(equalToConstant: diameter),
        circleContainerView.heightAnchor.constraint(equalToConstant: diameter),
    ])

    let image = Image.warning_circle.makeImage()
        .withTintColor(.textCritical)
    let imageView = UIImageView(image: image)
    circleContainerView.addAndPinSubview(
        imageView,
        insets: NSDirectionalEdgeInsets(
            top: 2,
            leading: 2,
            bottom: 2,
            trailing: 2
        )
    )

    return circleContainerView
}

#if DEBUG

import SwiftUI

private struct InstitutionIconViewUIViewRepresentable: UIViewRepresentable {

    private let institution: FinancialConnectionsInstitution = FinancialConnectionsInstitution(
        id: "123",
        name: "Chase",
        url: nil,
        icon: nil,
        logo: nil
    )
    let size: InstitutionIconView.Size
    let showWarning: Bool

    func makeUIView(context: Context) -> InstitutionIconView {
        InstitutionIconView(
            size: size,
            showWarning: showWarning
        )
    }

    func updateUIView(_ institutionIconView: InstitutionIconView, context: Context) {
        institutionIconView.setImageUrl(institution.icon?.default)
    }
}

struct InstitutionIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VStack(spacing: 10) {
                InstitutionIconViewUIViewRepresentable(
                    size: .large,
                    showWarning: true
                )

                InstitutionIconViewUIViewRepresentable(
                    size: .medium,
                    showWarning: false
                )

                InstitutionIconViewUIViewRepresentable(
                    size: .small,
                    showWarning: false
                )

                Spacer()
            }
            .frame(width: 40, height: 200)
            .padding()

            Spacer()
        }
    }
}

#endif
