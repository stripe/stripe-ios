//
//  STPFileClient.h
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STPFile.h"
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A client for interfacing with the Stripe file upload API.
 */
@interface STPFileClient : NSObject

/**
 *  A shared singleton file upload API client. Its API key will be initially equal to [Stripe defaultPublishableKey].
 */
+ (instancetype)sharedClient;

/**
 *  Creates a new STPFileClient instance with a publishable key.
 */
- (instancetype)initWithPublishableKey:(NSString *)publishableKey;

@end

/**
 *  STPFileClient extensions to upload files.
 */
@interface STPFileClient (Upload)

/**
 *  Uses the Stripe file upload API to upload an image. This can be used for identity veritfication and evidence disputes.
 *
 *  @param image The image to be uploaded. The maximum allowed file size is 4MB for identity documents and 8MB for evidence disputes. Cannot be nil. @see https://stripe.com/docs/file-upload
 *  @param purpose The purpose of this file. This can be either an identifing document or an evidence dispute.
 *  @param completion The callback to run with the returned Stripe file (and any errors that may have occurred).
 */
- (void)uploadImage:(UIImage *)image
            purpose:(STPFilePurpose)purpose
         completion:(nullable STPFileCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
