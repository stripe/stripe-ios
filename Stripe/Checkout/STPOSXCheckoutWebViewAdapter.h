//
//  STPOSXCheckoutWebViewAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE

#import "STPCheckoutWebViewAdapter.h"
#import <WebKit/WebKit.h>

@interface STPOSXCheckoutWebViewAdapter : NSObject<STPCheckoutWebViewAdapter>
@property (nonatomic) WebView *webView;
@end

#endif
