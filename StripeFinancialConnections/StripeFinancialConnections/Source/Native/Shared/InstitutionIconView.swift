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

    private lazy var institutionImageView: UIImageView = {
        let iconImageView = UIImageView()
        return iconImageView
    }()

    init() {
        super.init(frame: .zero)
        let diameter: CGFloat = 56
        let cornerRadius: CGFloat = 12
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter),
        ])

        addAndPinSubview(institutionImageView)
        institutionImageView.layer.cornerRadius = cornerRadius
        institutionImageView.clipsToBounds = true

        layer.shadowColor = UIColor.textDefault.cgColor
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
        institutionImageView.setImage(
            with: imageUrl,
            placeholder: Image.brandicon_default.makeImage()
        )
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
