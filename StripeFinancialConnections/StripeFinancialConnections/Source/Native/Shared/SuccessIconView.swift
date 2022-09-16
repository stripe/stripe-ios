//
//  SuccessIconView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/14/22.
//

import Foundation
import UIKit

final class SuccesIconView: UIView {
    
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        if #available(iOS 13.0, *) {
            let image = UIImage(systemName: "checkmark")?
                .withRenderingMode(.alwaysOriginal)
                .withTintColor(.textSuccess)
            iconImageView.image = image
        } else {
            assertionFailure()
        }
        return iconImageView
    }()
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.clear
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
        
        // Draw circle border
        layer.borderColor = UIColor.textSuccess.cgColor
        layer.borderWidth = 1.5
        layer.cornerRadius = bounds.size.width / 2.0
    }
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct SuccesIconViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> SuccesIconView {
        SuccesIconView()
    }
    
    func updateUIView(_ uiView: SuccesIconView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct SuccesIconView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {                
                SuccesIconViewUIViewRepresentable()
                    .frame(width: 40, height: 40)
                Spacer()
            }
            .padding()
        }
    }
}

#endif
