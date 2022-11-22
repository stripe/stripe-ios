//
//  STDSImageLoader.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^STDSImageDownloadCompletionBlock)(UIImage * _Nullable);

@interface STDSImageLoader: NSObject

/**
 Initializes an `STDSImageLoader` with the given parameters.

 @param session The session to initialize the loader with.
 @return Returns an initialized `STDSImageLoader` object.
 */
- (instancetype)initWithURLSession:(NSURLSession *)session;

/**
 Attempts to load an image from the specified URL.

 @param URL The URL to load an image for.
 @param completion A completion block that is called when the image loading has finished. This will be called on the main queue.
 */
- (void)loadImageFromURL:(NSURL *)URL completion:(STDSImageDownloadCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
