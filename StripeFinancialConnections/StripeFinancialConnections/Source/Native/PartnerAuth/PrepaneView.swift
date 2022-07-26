//
//  PrePaneView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/26/22.
//

import Foundation
import UIKit

final class PrepaneView: UIView {
    
    // institution // institution: manifest.active_institution,
    // partner (from the FLOW)
    // isSingleAccount // singleAccount: manifest.single_account,
    init(institutionName: String, partnerName: String?, isSingleAccount: Bool) {
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        
        // Link with {institution}
        
        let headerStackView = UIStackView(arrangedSubviews: [
            CreateIconView(),
            CreateTitleAndSubtitleView(
                title: "Link with \(institutionName)", // second part is INSTITUTION
                subtitle: "A new window will open for you to log in and select the \(institutionName) account(s) you want to link.\n\nThis page will update once you're done."
            ),
        ])
        // 'A new window will open for you to log in and select the {institution} account{isSingleAccount, select, true {} false {(s)}} you want to link.',
        //    description: 'description for pane to show before launching OAuth window',
        
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
        
        // TODO: Create a footer view
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func CreateIconView() -> UIView {
        let iconContainerView = UIView()
        iconContainerView.backgroundColor = .textDisabled
        iconContainerView.layer.cornerRadius = 6 // TODO(kgaidis): fix temporary "icon" styling before we get loading icons
        
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
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(institutionName: "Chase", partnerName: "Finicity", isSingleAccount: true)
    }
    
    func updateUIView(_ uiView: PrepaneView, context: Context) {}
}

struct PrepaneView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack {
            PrepaneViewUIViewRepresentable()
                .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.1))
    }
}

#endif
