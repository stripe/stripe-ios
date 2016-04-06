//
//  STPBasicSourceProvider.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPSourceProvider.h"

@interface STPBasicSourceProvider : NSObject<STPSourceProvider>

typedef void (^STPRetrieveSourcesBlock)(__nonnull STPSourceCompletionBlock completion);

- (nonnull instancetype)initWithRetrieveSourcesBlock:(nonnull STPRetrieveSourcesBlock)retrieveSourcesBlock;
- (void)addSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion;
@property(nonatomic, nullable, readonly)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable, readonly)id<STPSource> selectedSource;

@end
