//
//  ConsentHeaderView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ConsentHeaderView: UIView {
    
    init() {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.white
        
        let headerLabel = UILabel()
        headerLabel.numberOfLines = 0
        headerLabel.text = "Connect your Cash App account with Stripe."
        headerLabel.font = .stripeFont(forTextStyle: .subtitle)
        headerLabel.textColor = UIColor.black
        headerLabel.textAlignment = .left
        addSubview(headerLabel)
        
        let horizontalPadding: CGFloat = 24
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            headerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct ConsentHeaderViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentHeaderView {
        ConsentHeaderView()
    }

    func updateUIView(_ uiView: ConsentHeaderView, context: Context) {}
}

struct ConsentHeaderView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                ConsentHeaderViewUIViewRepresentable()
                    .background(Color.red)
                ScrollView {
                    Text("Scroll View Content")
                }
            }
            .background(Color.yellow)
        }
    }
}

#endif
