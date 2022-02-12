//
//  VerificationPageDataDocumentFileData.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/8/21.
//
import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataDocumentFileData: StripeEncodable, Equatable {

    enum FileUploadMethod: String, Encodable, Equatable {
        /// Document image was auto-captured from the camera feed using ML models
        case autoCapture = "auto_capture"
        /// Document was uploaded from the file system
        case fileUpload = "file_upload"
        /// Document image was captured from the camera feed manually
        case manualCapture = "manual_capture"
    }

    /// If auto-captured, probability score of 'back' result from ML model.
    let backScore: TwoDigitDecimal?
    /// If auto-captured, probability score of 'front_id' result from ML model.
    let frontCardScore: TwoDigitDecimal?
    /// File ID of uploaded image. If user auto-captured, this will be cropped to the bounds of the document.
    let highResImage: String
    /// If auto-captured, probability score of 'invalid' result from ML model.
    let invalidScore: TwoDigitDecimal?
    /// If auto-captured, file ID of uploaded un-cropped image.
    let lowResImage: String?
    /// If auto-captured, probability score of 'passport' result from ML model.
    let passportScore: TwoDigitDecimal?
    /// Method of getting the document image
    let uploadMethod: FileUploadMethod

    var _additionalParametersStorage: NonEncodableParameters?
}
