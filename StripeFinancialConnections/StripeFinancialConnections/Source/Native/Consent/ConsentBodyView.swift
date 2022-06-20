//
//  ConsentBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/15/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ConsentBodyView: UIView {
    init() {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.white
        
        let scrollView = UIScrollView()
        addAndPinSubview(scrollView)
        
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.addArrangedSubview(
            CreateLabelView(
                text: "Only the data requested is shared with [Merchant]. We never share your login details with them.",
                link: ClickableLabel.Link(
                    text: "data requested",
                    urlString: "https://www.google.com",
                    action: { url in
                        print("clicked link: \(url)")
                    }
                )
            )
        )
        verticalStackView.addArrangedSubview(
            CreateLabelView(
                text: "Your data is encrypted for your protection.",
                link: nil
            )
        )
        verticalStackView.addArrangedSubview(
            CreateLabelView(
                text: "You can disconnect your accounts at anytime.",
                link: ClickableLabel.Link(
                    text: "disconnect",
                    urlString: "https://www.google.com",
                    action: { url in
                        print("clicked link: \(url)")
                    }
                )
            )
        )
        scrollView.addSubview(verticalStackView)
        
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalPadding: CGFloat = 24
        NSLayoutConstraint.activate([
            verticalStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -(horizontalPadding * 2)),
            verticalStackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            verticalStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreateLabelView(text: String, link: ClickableLabel.Link?) -> UIView {
    let imageView = UIImageView(image: Image.close.makeImage(template: false))
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        // skip `imageView.heightAnchor` so the labels naturally expand
    ])
    
    let label = ClickableLabel()
    label.setText(text, link: link)

    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            imageView,
            label,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 10
    horizontalStackView.alignment = .top
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct ConsentBodyViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ConsentBodyView {
        ConsentBodyView()
    }
    
    func updateUIView(_ uiView: ConsentBodyView, context: Context) {}
}

struct ConsentBodyView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                Text("Header")
                ConsentBodyViewUIViewRepresentable()
                Text("Footer")
            }
        }
    }
}

#endif
