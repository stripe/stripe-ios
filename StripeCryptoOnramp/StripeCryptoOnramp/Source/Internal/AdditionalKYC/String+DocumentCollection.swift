//
//  String+DocumentCollection.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

extension String {

    /// The lowercase file extension, treating JPG and JPEG as the same format.
    var normalizedDocumentFileExtension: String {
        let fileExtension = lowercased()
        return fileExtension == "jpg" ? "jpeg" : fileExtension
    }
}
