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
    private static let size: CGSize = .init(width: 56, height: 56)

    private lazy var institutionImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
    }()

    init() {
        super.init(frame: .zero)
        let cornerRadius: CGFloat = 12
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Self.size.width),
            heightAnchor.constraint(equalToConstant: Self.size.height),
        ])

        addAndPinSubview(institutionImageView)
        institutionImageView.layer.cornerRadius = cornerRadius
        institutionImageView.clipsToBounds = true

        layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 1
        layer.shadowOffset = CGSize(
            width: 0,
            height: 1
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageUrl(_ imageUrl: String?) {
        let bankIconPlaceholder = CreateBankIconPlaceholder(size: Self.size)
        institutionImageView.setImage(
            with: imageUrl,
            placeholder: bankIconPlaceholder
        )
    }
}

private func CreateBankIconPlaceholder(size: CGSize) -> UIImage {
    let backgroundColor: UIColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
    let iconColor: UIColor = FinancialConnectionsAppearance.Colors.icon
    let iconSize: CGSize = CGSize(width: 24, height: 24)
    let icon: UIImage = Image.bank.makeImage(template: true)

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        // Draw background
        backgroundColor.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // Draw icon
        let iconRect = CGRect(
            x: (size.width - iconSize.width) / 2,
            y: (size.height - iconSize.height) / 2,
            width: iconSize.width,
            height: iconSize.height
        )
        icon.withTintColor(iconColor).draw(in: iconRect)
    }
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

    func makeUIView(context: Context) -> InstitutionIconView {
        InstitutionIconView()
    }

    func updateUIView(_ institutionIconView: InstitutionIconView, context: Context) {
        institutionIconView.setImageUrl(institution.icon?.default)
    }
}

struct InstitutionIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VStack(spacing: 20) {
                InstitutionIconViewUIViewRepresentable()
                    .frame(width: 56, height: 56)

                Spacer()
            }
            .frame(width: 100, height: 300)
            .padding()

            Spacer()
        }
    }
}

#endif
