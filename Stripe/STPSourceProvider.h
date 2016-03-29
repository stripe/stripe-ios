//
//  STPSourceProvider.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol STPSource;

typedef void (^STPSourceCompletionBlock)(id<STPSource> __nullable selectedSource, NSArray<id<STPSource>>* __nullable sources, NSError * __nullable error);

@protocol STPSourceProvider

- (void)retrieveSources:(nonnull STPSourceCompletionBlock)completion;
- (void)addSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion;
- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion;
@property(nonatomic, nullable, readonly)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable, readonly)id<STPSource> selectedSource;

@end
