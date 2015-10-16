//
//  STPAPIClient+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPAPIClient ()<NSURLSessionDelegate>

- (void)createTokenWithData:(nonnull NSData *)data completion:(nullable STPTokenCompletionBlock)completion;

@property (nonatomic, readwrite, nonnull) NSURL *apiURL;
@property (nonatomic, readwrite, nonnull) NSURLSession *urlSession;

@end
