//
//  STPMultipartFormDataPart.h
//  Stripe
//
//  Created by Charles Scalesse on 12/1/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Represents a single part of a multipart/form-data upload.
 @see https://www.w3.org/TR/html401/interact/forms.html#h-17.13.4
 */
@interface STPMultipartFormDataPart : NSObject

/**
 The data for this part.
 */
@property (nonatomic, copy) NSData *data;

/**
 The name for this part.
 */
@property (nonatomic, copy) NSString *name;

/**
 The filename for this part. As a rule of thumb, this can be ommitted when the data is just an encoded string. However, this is typically required for other types of binary file data (like images).
 */
@property (nonatomic, copy, nullable) NSString *filename;

/**
 The content type for this part. When omitted, the multipart/form-data standard assumes text/plain.
 */
@property (nonatomic, copy, nullable) NSString *contentType;

/**
 Returns the fully-composed data for this part.
 */
- (NSData *)composedData;

@end

NS_ASSUME_NONNULL_END
