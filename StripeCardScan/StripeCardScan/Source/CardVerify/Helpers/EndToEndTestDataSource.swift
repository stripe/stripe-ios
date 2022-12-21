//
//  EndToEndTestDataSource.swift
//  StripeCardScanTests
//
//  Created by Scott Grant on 9/25/22.
//

#if targetEnvironment(simulator)

    import Foundation
    import UIKit

    class EndToEndTestingImageDataSource: TestingImageDataSource {
        lazy var testImages: [UIImage] = {
            let bundle = Bundle(for: EndToEndTestingImageDataSource.self)
            let path = bundle.url(forResource: "synthetic_test_image", withExtension: "jpg")!
            let image = UIImage(contentsOfFile: path.path)!
            return [image]
        }()

        lazy var currentTestImages: [CGImage]? = {
            self.testImages.compactMap { $0.cgImage }
        }()

        func nextSquareAndFullImage() -> CGImage? {
            guard let targetSize = UIApplication.shared.windows.first?.frame.size else {
                return nil
            }

            guard let fullCardImage = self.currentTestImages?.first else {
                return nil
            }

            let resultImage = fullCardImage.extendedEdges(targetSize: targetSize)

            self.currentTestImages = self.currentTestImages?.dropFirst().map { $0 }

            guard let testImageCount = self.currentTestImages?.count else { return nil }

            if testImageCount == 0 {
                self.currentTestImages = self.testImages.compactMap { $0.cgImage }
            }

            return resultImage
        }
    }

#endif  // targetEnvironment(simulator)
