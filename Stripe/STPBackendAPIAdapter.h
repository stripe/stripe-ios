//
//  STPBackendAPIAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STPAddress.h"

@protocol STPSource;

typedef void (^STPSourceCompletionBlock)(id<STPSource> __nullable selectedSource, NSArray<id<STPSource>>* __nullable sources, NSError * __nullable error);
typedef void (^STPAddressCompletionBlock)(STPAddress * __nullable address, NSError * __nullable error);

@protocol STPBackendAPIAdapter<NSObject>

- (void)retrieveSources:(nonnull STPSourceCompletionBlock)completion;
- (void)addSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion;
- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion;

@end
