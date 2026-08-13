import Foundation
@_spi(STP) import StripeCore
import UIKit

extension STPAPIClient {
    func get<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            get(
                resource: resource,
                parameters: parameters,
                ephemeralKeySecret: ephemeralKeySecret,
                consumerPublishableKey: consumerPublishableKey,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }

    func post<T: Decodable>(
        resource: String,
        parameters: [String: Any],
        ephemeralKeySecret: String? = nil,
        consumerPublishableKey: String? = nil
    ) async throws -> T {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            post(
                resource: resource,
                parameters: parameters,
                ephemeralKeySecret: ephemeralKeySecret,
                consumerPublishableKey: consumerPublishableKey,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }

    func post<I: Encodable, O: Decodable>(
        resource: String,
        object: I,
        ephemeralKeySecret: String? = nil
    ) async throws -> O {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<O, Error>) in
            post(
                resource: resource,
                object: object,
                ephemeralKeySecret: ephemeralKeySecret,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }

    func uploadImageAndGetMetrics(
        _ image: UIImage,
        compressionQuality: CGFloat = UIImage.defaultCompressionQuality,
        purpose: String,
        fileName: String = defaultImageFileName,
        ownedBy: String? = nil,
        ephemeralKeySecret: String? = nil
    ) async throws -> FileAndUploadMetrics {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FileAndUploadMetrics, Error>) in
            uploadImageAndGetMetrics(
                image,
                compressionQuality: compressionQuality,
                purpose: purpose,
                fileName: fileName,
                ownedBy: ownedBy,
                ephemeralKeySecret: ephemeralKeySecret,
                completion: { result in
                    continuation.resume(with: result)
                }
            )
        }
    }
}
