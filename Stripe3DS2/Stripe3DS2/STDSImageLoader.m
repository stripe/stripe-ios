//
//  STDSImageLoader.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSImageLoader()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation STDSImageLoader

- (instancetype)initWithURLSession:(NSURLSession *)session {
    self = [super init];
    
    if (self) {
        _session = session;
    }
    
    return self;
}

- (void)loadImageFromURL:(NSURL *)URL completion:(STDSImageDownloadCompletionBlock)completion {
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        UIImage *image;
        
        if (data != nil) {
            image =  [UIImage imageWithData:data];
        }
        
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            completion(image);
        }];
    }];
    
    [dataTask resume];
}

@end

NS_ASSUME_NONNULL_END
