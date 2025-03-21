//
//  ConsentLogoView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/22/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

private let blurRadius = 3
private let ellipsisViewWidth: CGFloat = 32.0

final class ConsentLogoView: UIView {

    private var multipleDotView: UIView?
    private var shadowLayers: [CALayer] = []

    init(merchantLogo: [String], showsAnimatedDots: Bool) {
        super.init(frame: .zero)
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center

        if merchantLogo.count == 2 || merchantLogo.count == 3 {
            for i in 0..<merchantLogo.count {
                let urlString = merchantLogo[i]
                let logoView = CreateRoundedLogoView(urlString: urlString)
                self.shadowLayers.append(logoView.layer)
                horizontalStackView.addArrangedSubview(logoView)

                let isLastLogo = (i == merchantLogo.count - 1)
                if !isLastLogo, showsAnimatedDots {
                    let ellipsisViewTuple = CreateEllipsisView(
                        leftLogoUrl:
                            merchantLogo[i],
                        rightLogoUrl: merchantLogo[i+1]
                    )
                    self.multipleDotView = ellipsisViewTuple.multipleDotView
                    horizontalStackView.addArrangedSubview(
                        ellipsisViewTuple.ellipsisView
                    )
                    animateDots()
                }
            }
        }

        if !showsAnimatedDots {
            horizontalStackView.spacing = 16
        }

        addAndPinSubview(
            CreateCenteringView(
                centeredView: horizontalStackView
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animateDots() {
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["UITesting"] != nil {
            return
        }
#endif
        guard let multipleDotView = multipleDotView else {
            return
        }

        // remove any previous animations if-needed
        multipleDotView.layer.removeAllAnimations()

        multipleDotView.frame = CGRect(
            x: -multipleDotView.bounds.width + ellipsisViewWidth,
            y: 0,
            width: multipleDotView.bounds.width,
            height: multipleDotView.bounds.height
        )
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            options: [.repeat, .curveLinear],
            animations: {
                multipleDotView.frame = CGRect(
                    x: multipleDotView.frame.minX + MultipleDotView.dotRadius + MultipleDotView.dotSpacing,
                    y: 0,
                    width: multipleDotView.bounds.width,
                    height: multipleDotView.bounds.height
                )
            }
        )
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        for shadow in shadowLayers {
            shadow.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
        }
    }
}

private func CreateEllipsisView(
    leftLogoUrl: String?,
    rightLogoUrl: String?
) -> (ellipsisView: UIView, multipleDotView: UIView) {
    let backgroundView = MergedLogoView(
        leftImageUrl: leftLogoUrl,
        rightImageUrl: rightLogoUrl
    )
    backgroundView.clipsToBounds = true
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        backgroundView.widthAnchor.constraint(equalToConstant: ellipsisViewWidth),
        backgroundView.heightAnchor.constraint(equalToConstant: 6),
    ])

    let multipleDotView = MultipleDotView()
    backgroundView.mask = multipleDotView

    return (backgroundView, multipleDotView)
}

private func CreateCenteringView(centeredView: UIView) -> UIView {
    let leftSpacerView = UIView()
    leftSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    let rightSpacerView = UIView()
    rightSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    let horizontalStackView = UIStackView(
        arrangedSubviews: [leftSpacerView, centeredView, rightSpacerView]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.distribution = .equalCentering
    horizontalStackView.alignment = .center
    return horizontalStackView
}

/// A view that blurs two logos together.
///
/// Takes two logos. Puts one on the left side. Puts the other on the right side.
/// The logos are allocated half the width of the view, are blurred,
/// and then overlap at the middle.
private class MergedLogoView: UIView {

    private lazy var leftImageView: UIImageView = {
        let leftImageView = BlurredImageView()
        return leftImageView
    }()
    private lazy var rightImageView: UIImageView = {
        let rightImageView = BlurredImageView()
        return rightImageView
    }()

    init(leftImageUrl: String?, rightImageUrl: String?) {
        super.init(frame: .zero)
        addSubview(rightImageView)
        // add the `left` over `right` to prioritize the
        // left image in the overlap as its the 'dominant' one
        addSubview(leftImageView)
        leftImageView.setImage(with: leftImageUrl) { [weak self] _ in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        }
        rightImageView.setImage(with: rightImageUrl) { [weak self] _ in
            self?.setNeedsLayout()
            self?.layoutIfNeeded()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // an estimated value to overlap the two blurred
        // images while avoiding white-space
        let imageOverlapWidth: CGFloat = CGFloat(blurRadius) * 4.5

        let leftImageSize = leftImageView.image?.size ?? CGSize(
            width: bounds.width / 2,
            height: bounds.height / 2
        )
        leftImageView.frame = CGRect(
            x: -leftImageSize.width + (bounds.width / 2) + (imageOverlapWidth),
            y: -(leftImageSize.height / 2) + (bounds.height / 2),
            width: leftImageSize.width,
            height: leftImageSize.height
        )

        let rightImageSize = rightImageView.image?.size ?? CGSize(
            width: bounds.width / 2,
            height: bounds.height / 2
        )
        rightImageView.frame = CGRect(
            x: bounds.width / 2 - (imageOverlapWidth),
            y: -(rightImageSize.height / 2) + (bounds.height / 2),
            width: rightImageSize.width,
            height: rightImageSize.height
        )
    }
}

// A view that renders multiple dots (like an ellipis).
private class MultipleDotView: UIView {

    private static let numberOfDots = 5
    static let dotSpacing: CGFloat = 4.0
    static let dotRadius: CGFloat = 6.0
    static let size = CGSize(
        width: CGFloat(numberOfDots) * dotRadius + CGFloat(numberOfDots - 1) * dotSpacing,
        height: dotRadius
    )

    override init(frame: CGRect) {
        super.init(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Self.size.width,
                height: Self.size.height
            )
        )

        var currentX: CGFloat = 0
        for _ in 0..<Self.numberOfDots {
            let dotView = DotView()
            dotView.backgroundColor = .black
            dotView.frame = CGRect(
                x: currentX,
                y: 0,
                width: Self.dotRadius,
                height: Self.dotRadius
            )
            dotView.autoresizingMask = [.flexibleRightMargin]
            addSubview(dotView)
            currentX += Self.dotRadius + Self.dotSpacing
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class DotView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}

// Blurs the `image` set on the `UIImageView`
private class BlurredImageView: UIImageView {
    override var image: UIImage? {
        get {
            return super.image
        }
        set {
            if let newImage = newValue {
                // set the image before its blurred so
                // we can use it for sizing calculation
                super.image = newImage
                Self.applyHorizontalBlur(to: newImage) { blurredImage in
                    DispatchQueue.main.async {
                        super.image = blurredImage
                    }
                }
            } else {
                super.image = nil
            }
        }
    }

    private static func applyHorizontalBlur(
        to originalImage: UIImage,
        completionHandler: @escaping (UIImage?) -> Void
    ) {
        DispatchQueue.global(qos: .default).async {
            guard let inputCIImage = CIImage(image: originalImage) else {
                DispatchQueue.main.async {
                    completionHandler(originalImage)
                }
                return
            }

            let motionBlurFilter = CIFilter(name: "CIMotionBlur")
            motionBlurFilter?.setValue(inputCIImage, forKey: kCIInputImageKey)
            motionBlurFilter?.setValue(NSNumber(value: blurRadius), forKey: kCIInputRadiusKey)

            guard let blurredCIImage = motionBlurFilter?.outputImage else {
                DispatchQueue.main.async {
                    completionHandler(originalImage)
                }
                return
            }

            let context = CIContext()
            guard
                let cgImage = context.createCGImage(blurredCIImage, from: blurredCIImage.extent)
            else {
                DispatchQueue.main.async {
                    completionHandler(originalImage)
                }
                return
            }

            let finalImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                completionHandler(finalImage)
            }
        }
    }
}

#if DEBUG

import SwiftUI

private struct ConsentLogoViewUIViewRepresentable: UIViewRepresentable {

    var showsAnimatedDots: Bool

    func makeUIView(context: Context) -> ConsentLogoView {
        ConsentLogoView(
            merchantLogo: [
                "https://stripe-camo.global.ssl.fastly.net/a2f7a55341b7cdb849d5b2d68a465f95cc06ee6ec2449ea468b3623a61c17393/68747470733a2f2f66696c65732e7374726970652e636f6d2f6c696e6b732f4d44423859574e6a64463878546d5978575664445356553457474a6f52326c5966475a7358327870646d56664d58526f617a5a526454523354573144566a4a4e57584659526d6c3161464646303077384f5a645a3166",
                "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png",
            ],
            showsAnimatedDots: showsAnimatedDots
        )
    }

    func updateUIView(_ uiView: ConsentLogoView, context: Context) {}
}

struct ConsentLogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center) {
            ConsentLogoViewUIViewRepresentable(showsAnimatedDots: true)
            Spacer()
            ConsentLogoViewUIViewRepresentable(showsAnimatedDots: false)
        }
        .padding()
    }
}

#endif
