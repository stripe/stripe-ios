//
//  STPIOSCheckoutWebViewAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
@import Foundation;
@import UIKit;

#import "STPCheckoutWebViewAdapter.h"


@interface STPIOSCheckoutWebViewAdapter : NSObject<STPCheckoutWebViewAdapter, UIWebViewDelegate>
@property (nonatomic, nullable) UIWebView *webView;
@end

#endif
