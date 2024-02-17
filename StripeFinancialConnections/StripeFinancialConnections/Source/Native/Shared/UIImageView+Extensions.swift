//
//  UIImageView+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/11/22.
//

import Foundation
import UIKit

extension UIImageView {

    func setImage(
        with urlString: String?,
        placeholder: UIImage? = nil,
        useAlwaysTemplateRenderingMode: Bool = false,
        completionHandler: ((_ didDownloadImage: Bool) -> Void)? = nil
    ) {
        if let placeholder = placeholder {
            image = placeholder
        }

        guard let urlString = urlString else {
            completionHandler?(false)
            return
        }

        // We use `tag` to ensure that if we call `setImage(with:)` multiple times,
        // we ONLY set the image from the `urlString` for the last `urlString` passed.
        //
        // This avoids async bugs where an older image could override a newer image.
        tag = urlString.hashValue
        DownloadImage(urlString: urlString) { [weak self] image in
            if let image = image {
                DispatchQueue.main.async {
                    if self?.tag == urlString.hashValue {
                        if useAlwaysTemplateRenderingMode {
                            // this ensures that if `UIImageView.tintColor` is set,
                            // the image will be re-colored according to `tintColor`
                            self?.image = image.withRenderingMode(.alwaysTemplate)
                        } else {
                            self?.image = image
                        }
                        completionHandler?(true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    if self?.tag == urlString.hashValue {
                        completionHandler?(false)
                    }
                }
            }
        }
    }
}

private func DownloadImage(
    urlString: String,
    completionHandler: @escaping (UIImage?) -> Void
) {
    guard let url = URL(string: urlString) else {
        completionHandler(nil)
        return
    }
    URLSession.shared.dataTask(with: url) { data, response, _ in
        guard let response = response as? HTTPURLResponse else {
            assertionFailure("we always expect to get back `HTTPURLResponse`")
            completionHandler(nil)
            return
        }
        if response.statusCode == 200, let data = data, let image = UIImage(data: data) {
            completionHandler(image)
        } else {
            completionHandler(nil)
        }
    }
    .resume()
}
