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

typedef void (^STPSourceRetrieveCompletionBlock)(id<STPSource> __nullable selectedSource, NSArray<id<STPSource>>* __nullable sources, NSError * __nullable error);
typedef void (^STPSourceCreateCompletionBlock)(id<STPSource> __nullable selectedSource, NSArray<id<STPSource>>* __nullable sources, NSError * __nullable error);

@protocol STPSourceProvider

- (void)retrieveSources:(nonnull STPSourceRetrieveCompletionBlock)completion;
- (void)addSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCreateCompletionBlock)completion;
- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCreateCompletionBlock)completion;
@property(nonatomic, nullable, readonly)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable, readonly)id<STPSource> selectedSource;

@end
