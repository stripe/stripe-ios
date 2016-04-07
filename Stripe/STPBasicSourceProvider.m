//
//  STPBasicSourceProvider.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBasicSourceProvider.h"

@interface STPBasicSourceProvider()
@property(nonatomic, copy)STPRetrieveSourcesBlock retrieveSourcesBlock;
@property(nonatomic, nullable)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable)id<STPSource> selectedSource;
@end

@implementation STPBasicSourceProvider

- (instancetype)init {
    return [self initWithRetrieveSourcesBlock:^(STPSourceCompletionBlock  _Nonnull completion) {
        completion(self.selectedSource, self.sources, nil);
    }];
}

- (instancetype)initWithRetrieveSourcesBlock:(STPRetrieveSourcesBlock)retrieveSourcesBlock {
    self = [super init];
    if (self) {
        _sources = @[];
        _retrieveSourcesBlock = retrieveSourcesBlock;
    }
    return self;
}

- (void)retrieveSources:(STPSourceCompletionBlock)completion {
    __weak STPBasicSourceProvider *weakself = self;
    self.retrieveSourcesBlock(^(id<STPSource> _Nullable selectedSource, NSArray<id<STPSource>> * _Nullable sources, NSError * _Nullable error) {
        if (error) {
            completion(nil, nil, error);
            return;
        }
        weakself.selectedSource = selectedSource;
        weakself.sources = sources;
        completion(selectedSource, sources, error);
    });
}

- (void)addSource:(id<STPSource>)source completion:(STPSourceCompletionBlock)completion {
    self.sources = [self.sources arrayByAddingObject:source];
    [self selectSource:source completion:completion];
}

- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion {
    self.selectedSource = source;
    completion(source, self.sources, nil);
}

@end
