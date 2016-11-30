//
//  STPFile.h
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

typedef NS_ENUM(NSInteger, STPFilePurpose) {
    STPFilePurposeIdentityDocument,
    STPFilePurposeDisputeEvidence
};

@interface STPFile : NSObject <STPAPIResponseDecodable>

/**
 *  The token for this file.
 */
@property (nonatomic, readonly, nonnull) NSString *fileId;

/**
 * The date this file was created.
 */
@property (nonatomic, readonly, nonnull) NSDate *created;

/**
 * The purpose of this file, either an identifing document or an evidence dispute document. @see https://stripe.com/docs/file-upload
 */
@property (nonatomic, readonly) STPFilePurpose purpose;

/**
 * The file size in bytes.
 */
@property (nonatomic, readonly, nonnull) NSNumber *size;

/**
 * The publicly accessible URL to view the uploaded file. For security purposes, the url parameter will be nil for identity document uploads.
 */
@property (nonatomic, readonly, nullable) NSURL *url;

/**
 * The mime type for this file. This can be image/jpeg, image/png, or application/pdf.
 */
@property (nonatomic, readonly, nonnull) NSString *mimeType;

@end
