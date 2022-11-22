//
//  STDSDemoViewController.h
//  Stripe3DS2DemoUI
//
//  Created by Andrew Harrison on 3/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSImageLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSDemoViewController: UIViewController

- (instancetype)initWithImageLoader:(STDSImageLoader *)imageLoader;

@end

NS_ASSUME_NONNULL_END
