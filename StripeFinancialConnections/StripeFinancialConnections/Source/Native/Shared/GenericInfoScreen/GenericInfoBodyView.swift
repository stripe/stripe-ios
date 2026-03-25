//
//  GenericInfoBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/24.
//

import Foundation
import UIKit

func GenericInfoBodyView(
    body: FinancialConnectionsGenericInfoScreen.Body?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView? {
    guard let body, !body.entries.isEmpty else {
        return nil
    }
    let verticalStackView = HitTestStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 0
    for entry in body.entries {
        let entryView: UIView?
        switch entry {
        case .text(let textBodyEntry):
            entryView = TextBodyEntryView(
                textBodyEntry,
                didSelectURL: didSelectURL
            )
        case .image(let imageBodyEntry):
            entryView = ImageBodyEntryView(imageBodyEntry)
        case .bullets(let bulletsBodyEntry):
            entryView = BulletsBodyEntryView(
                bulletsBodyEntry,
                didSelectURL: didSelectURL
            )
        case .unparasable:
            entryView = nil // skip
        }
        if let entryView {
            verticalStackView.addArrangedSubview(entryView)
        }
    }
    // check `isEmpty` in case we were not able to handle any entry type
    return verticalStackView.arrangedSubviews.isEmpty ? nil : verticalStackView
}

// MARK: - Text

private func TextBodyEntryView(
    _ textBodyEntry: FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let font: FinancialConnectionsFont
    let boldFont: FinancialConnectionsFont
    let textColor: UIColor
    switch textBodyEntry.size {
    case .xsmall:
        font = .body(.extraSmall)
        boldFont = .body(.extraSmallEmphasized)
        textColor = FinancialConnectionsAppearance.Colors.textSubdued
    case .small:
        font = .body(.small)
        boldFont = .body(.smallEmphasized)
        textColor = FinancialConnectionsAppearance.Colors.textSubdued
    case .medium: fallthrough
    case .unparsable: fallthrough
    case .none:
        font = .body(.medium)
        boldFont = .body(.mediumEmphasized)
        textColor = FinancialConnectionsAppearance.Colors.textDefault
    }
    let textView = AttributedTextView(
        font: font,
        boldFont: boldFont,
        linkFont: font,
        textColor: textColor,
        alignment: {
            switch textBodyEntry.alignment {
            case .center:
                return .center
            case .right:
                return .right
            case .left: fallthrough
            case .unparsable: fallthrough
            case .none:
                return .left
            }
        }()
    )
    textView.setText(
        textBodyEntry.text,
        action: didSelectURL
    )
    return textView
}

// MARK: - Image

private func ImageBodyEntryView(
    _ imageBodyEntry: FinancialConnectionsGenericInfoScreen.Body.ImageBodyEntry
) -> UIView? {
    guard let imageUrlString = imageBodyEntry.image.default else {
        return nil
    }
    let imageView = AutoResizableImageView()
    imageView.setImage(with: imageUrlString)
    return imageView
}

// `UIImageView` that will autoresize itself to be
// full width, but maintain aspect ratio height
private class AutoResizableImageView: UIImageView {

    override var intrinsicContentSize: CGSize {
        if let image, image.size.width > 0 {
            let height = image.size.height * (bounds.width / image.size.width)
            return CGSize(
                width: UIView.noIntrinsicMetric,
                height: height
            )
        } else {
            return CGSize(
                width: UIView.noIntrinsicMetric,
                height: 200 // give some height with assumption that an image will load
            )
        }
    }

    override var image: UIImage? {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}

// MARK: - Bullets

private func BulletsBodyEntryView(
    _ bulletsBodyEntry: FinancialConnectionsGenericInfoScreen.Body.BulletsBodyEntry,
    didSelectURL: @escaping (URL) -> Void
) -> UIView? {
    guard !bulletsBodyEntry.bullets.isEmpty else {
        return nil
    }
    let verticalStackView = HitTestStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    bulletsBodyEntry.bullets.forEach { genericBulletPoint in
        verticalStackView.addArrangedSubview(
            SingleBulletPointView(
                title: genericBulletPoint.title,
                content: genericBulletPoint.content,
                iconUrlString: genericBulletPoint.icon?.default,
                didSelectUrl: didSelectURL
            )
        )
    }
    return verticalStackView
}

private func SingleBulletPointView(
    title: String?,
    content: String?,
    iconUrlString: String?,
    didSelectUrl: @escaping (URL) -> Void
) -> UIView {
    let horizontalStackView = HitTestStackView()
    let labelView = BulletPointLabelView(
        title: title,
        content: content,
        didSelectURL: didSelectUrl
    )
    if let iconUrlString {
        horizontalStackView.addArrangedSubview(
            {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.setImage(with: iconUrlString)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                let imageDiameter: CGFloat = 20
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: imageDiameter),
                    imageView.heightAnchor.constraint(equalToConstant: imageDiameter),
                ])
                // add padding to the `imageView` so the
                // image is aligned with the label
                let paddingStackView = UIStackView(
                    arrangedSubviews: [imageView]
                )
                paddingStackView.isLayoutMarginsRelativeArrangement = true
                paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                    // center the image in the middle of the first line height
                    top: max(0, (labelView.topLineHeight - imageDiameter) / 2),
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                return paddingStackView
            }()
        )
    }
    horizontalStackView.addArrangedSubview(labelView)
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 16
    horizontalStackView.alignment = .top
    return horizontalStackView
}

// MARK: - SwiftUI Preview

#if DEBUG

import SwiftUI

@available(iOS 14.0, *)
private struct GenericInfoBodyViewUIViewRepresentable: UIViewRepresentable {

    let body: FinancialConnectionsGenericInfoScreen.Body

    func makeUIView(context: Context) -> UIView {
        return AutoResizableUIView(
            contentView: GenericInfoBodyView(
                body: body,
                didSelectURL: { _ in }
            )!
        )
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOS 14.0, *)
struct GenericInfoBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GenericInfoBodyViewUIViewRepresentable(
                body: FinancialConnectionsGenericInfoScreen.Body(
                    entries: [
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(nil) - Size (nil)",
                                alignment: nil,
                                size: nil
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(left) - Size (xsmall)",
                                alignment: .left,
                                size: .xsmall
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(center) - Size (small)",
                                alignment: .center,
                                size: .small
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(right) - Size (medium)",
                                alignment: .right,
                                size: .medium
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "vvv Image Item Expected Below vvv",
                                alignment: .center,
                                size: nil
                            )
                        ),
                        .image(
                            FinancialConnectionsGenericInfoScreen.Body.ImageBodyEntry(
                                id: "",
                                image: FinancialConnectionsImage(
                                    default: "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png"
                                ),
                                alt: ""
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "^^^ Image Item Expected Above ^^^",
                                alignment: .center,
                                size: nil
                            )
                        ),
                        .bullets(
                            FinancialConnectionsGenericInfoScreen.Body.BulletsBodyEntry(
                                id: "",
                                bullets: [
                                    .init(
                                        id: "",
                                        icon: FinancialConnectionsImage(
                                            default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--lock-primary-3x.png"
                                        ),
                                        title: "Bullet Title",
                                        content: "Bullet Content"
                                    ),
                                    .init(
                                        id: "String",
                                        icon: nil,
                                        title: "Bullet Title",
                                        content: nil
                                    ),
                                    .init(
                                        id: "",
                                        icon: FinancialConnectionsImage(
                                            default: "https://b.stripecdn.com/connections-statics-srv/assets/SailIcon--lock-primary-3x.png"
                                        ),
                                        title: nil,
                                        content: "Stripe will allow Goldilocks to access only the [data requested](https://www.stripe.com). We never share your login details with them."
                                    ),
                                ]
                            )
                        ),
                    ]
                )
            )
            .applyAutoResizableUIViewModifier()
            .padding()
            Spacer()
        }
    }
}

#endif
