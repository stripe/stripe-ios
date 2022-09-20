//
//  InstitutionSearchFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/19/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchFooterView: UIView {
    
    init() {
        super.init(frame: .zero)
        
        let titleLabel = UILabel()
        titleLabel.text = "CAN'T FIND YOUR BANK?"
        titleLabel.font = .stripeFont(forTextStyle: .kicker)
        titleLabel.textColor = .textSecondary
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                titleLabel,
                CreateRowView(
                    icon: "checkmark",
                    title: "Double check your spelling and search terms"
                ),
                CreateRowView(
                    icon: "pencil",
                    title: "[Manually add your account](https://www.meow.com)"
                ),
                CreateRowView(
                    icon: "envelope.fill",
                    title: "[Questions? Contact Support](https://www.meow.com)"
                ),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 20,
            leading: 24,
            bottom: 20,
            trailing: 24
        )
        verticalStackView.backgroundColor = .backgroundContainer
        
        let topSeparatorView = UIView()
        topSeparatorView.backgroundColor = .borderNeutral
        
        let bottomSeparatorView = UIView()
        bottomSeparatorView.backgroundColor = .borderNeutral
        
        addAndPinSubview(verticalStackView)
        addSubview(topSeparatorView)
        addSubview(bottomSeparatorView)
        
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSeparatorView.topAnchor.constraint(equalTo: topAnchor),
            topSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
            
            bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
private func CreateRowView(
    icon: String,
    title: String
) -> UIView {
    let shouldHighlightIcon = !title.extractLinks().links.isEmpty
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            CreateRowIconView(
                icon: icon,
                isHighlighted: shouldHighlightIcon
            ),
            CreateRowLabelView(
                title: title
            ),
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    return horizontalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateRowIconView(icon: String, isHighlighted: Bool) -> UIView {
    let iconContainerView = UIView()
    iconContainerView.backgroundColor = isHighlighted ? .info100 : .borderNeutral
    iconContainerView.layer.cornerRadius = 4
    
    let imageView = UIImageView()
    if #available(iOS 13.0, *) {
        imageView.image = UIImage(systemName: icon)?
            .withTintColor(
                isHighlighted ? .textBrand : .textSecondary,
                renderingMode: .alwaysOriginal
            )
            .applyingSymbolConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
    }
    
    imageView.contentMode = .scaleAspectFit
    iconContainerView.addSubview(imageView)
    
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 32),
        iconContainerView.heightAnchor.constraint(equalToConstant: 32),
        
//        imageView.widthAnchor.constraint(equalToConstant: 16),
        imageView.heightAnchor.constraint(equalToConstant: 16),
        imageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
    ])
    return iconContainerView
}

@available(iOSApplicationExtension, unavailable)
private func CreateRowLabelView(title: String) -> UIView {
    let titleLabel = ClickableLabel()
    titleLabel.setText(
        title,
        font: .stripeFont(forTextStyle: .captionTightEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
        textColor: .textPrimary
    )
    return titleLabel
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct InstitutionSearchFooterViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> InstitutionSearchFooterView {
        InstitutionSearchFooterView()
    }
    
    func updateUIView(_ uiView: InstitutionSearchFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct InstitutionSearchFooterView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                InstitutionSearchFooterViewUIViewRepresentable()
                    .frame(maxHeight: 240)
                Spacer()
            }
            .padding()
        }
    }
}

#endif
