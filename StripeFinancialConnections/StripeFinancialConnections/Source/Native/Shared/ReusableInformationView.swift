//
//  InformationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import Foundation
import UIKit

/// A reusable view that allows developers to quickly
/// render information.
final class ReusableInformationView: UIView {
    
    enum IconType {
        case loading
    }
    
    init(
        iconType: IconType,
        title: String,
        subtitle: String
    ) {
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        let headerStackView = UIStackView(arrangedSubviews: [
            CreateIconView(iconType: iconType),
            CreateTitleAndSubtitleView(title: title, subtitle: subtitle),
        ])
        headerStackView.axis = .vertical
        headerStackView.spacing = 16
        headerStackView.alignment = .leading
        addSubview(headerStackView)
        
        let horizontalPadding: CGFloat = 24
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateIconView(iconType: ReusableInformationView.IconType) -> UIView {
    let iconContainerView = UIView()
    iconContainerView.backgroundColor = .textBrand
    iconContainerView.layer.cornerRadius = 20 // TODO(kgaidis): fix temporary "icon" styling before we get loading icons
    
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 40),
        iconContainerView.heightAnchor.constraint(equalToConstant: 40),
    ])
    return iconContainerView
}

private func CreateTitleAndSubtitleView(title: String, subtitle: String) -> UIView {
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = .textPrimary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    let subtitleLabel = UILabel()
    subtitleLabel.font = .stripeFont(forTextStyle: .body)
    subtitleLabel.textColor = .textSecondary
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle
    let labelStackView = UIStackView(arrangedSubviews: [
        titleLabel,
        subtitleLabel,
    ])
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    return labelStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct ReusableInformationViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ReusableInformationView {
        ReusableInformationView(
            iconType: .loading,
            title: "Establishing connection",
            subtitle: "Please wait while a connection is established."
        )
    }
    
    func updateUIView(_ uiView: ReusableInformationView, context: Context) {}
}

struct ReusableInformationView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack {
            ReusableInformationViewUIViewRepresentable()
                .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#endif
