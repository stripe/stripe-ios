//
//  STPFile.h
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPFilePurpose) {
    STPFilePurposeIdentityDocument,
    STPFilePurposeDisputeEvidence,
    STPFilePurposeUnknown,
};

@interface STPFile : NSObject <STPAPIResponseDecodable>

/**
 *  The token for this file.
 */
@property (nonatomic, readonly) NSString *fileId;

/**
 * The date this file was created.
 */
@property (nonatomic, readonly) NSDate *created;

/**
 * The purpose of this file. This can be either an identifing document or an evidence dispute. 
 * @see https://stripe.com/docs/file-upload
 */
@property (nonatomic, readonly) STPFilePurpose purpose;

/**
 * The file size in bytes.
 */
@property (nonatomic, readonly) NSNumber *size;

/**
 * The file type. This can be "jpg", "png", or "pdf".
 */
@property (nonatomic, readonly) NSString *type;

/**
 * Returns the string value for a purpose.
 */
+ (NSString *)stringFromPurpose:(STPFilePurpose)purpose;

@end

NS_ASSUME_NONNULL_END
