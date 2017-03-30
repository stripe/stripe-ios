//
//  STPURLCallbackHandler.h
//  Stripe
//
//  Created by Brian Dorfman on 10/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STPURLCallbackListener <NSObject>
- (BOOL)handleURLCallback:(NSURL *)url;
@end

@interface STPURLCallbackHandler : NSObject

+ (instancetype)shared;

- (BOOL)handleURLCallback:(NSURL *)url;
- (void)registerListener:(id<STPURLCallbackListener>)listener
                  forURL:(NSURL *)url;

- (void)unregisterListener:(id<STPURLCallbackListener>)listener;

@end

NS_ASSUME_NONNULL_END
