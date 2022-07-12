//
//  ConsentBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/15/22.
//

import Foundation
import SafariServices
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ConsentBodyView: UIView {
    
    private let bulletItems: [ConsentModel.BodyBulletItem]
    
    init(
        bulletItems: [ConsentModel.BodyBulletItem],
        viewController: UIViewController
    ) {
        self.bulletItems = bulletItems
        super.init(frame: .zero)
        
        backgroundColor = UIColor.white
        
        let scrollView = UIScrollView()
        addAndPinSubview(scrollView)
        
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        
        let linkAction: (URL) -> Void = { [weak viewController] url in
            guard let viewController = viewController else {
                return
            }
            if let scheme = url.scheme, scheme.contains("stripe") {
                // TODO(kgaidis): open bottom sheet
                print("open bottom sheet")
            } else {
                SFSafariViewController.present(url: url, from: viewController)
            }
        }
        bulletItems.forEach { item in
            let bodyTextLinks = item.text.extractLinks()
            verticalStackView.addArrangedSubview(
                CreateLabelView(
                    text: bodyTextLinks.linklessString,
                    links: bodyTextLinks.links.map {
                        ClickableLabel.Link(range: $0.range, urlString: $0.urlString, action: linkAction)
                    }
                )
            )
        }
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

private func CreateLabelView(text: String, links: [ClickableLabel.Link]) -> UIView {
    let imageView = UIImageView(image: Image.close.makeImage(template: false))
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        // skip `imageView.heightAnchor` so the labels naturally expand
    ])
    
    let label = ClickableLabel()
    label.setText(text, links: links)

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
        ConsentBodyView(
            bulletItems: [
                ConsentModel.BodyBulletItem(
                    iconUrl: URL(string: "https://www.google.com/image.png")!,
                    text: "You can [disconnect](meow.com) your accounts at any time.")
            ],
            viewController: UIViewController()
        )
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
