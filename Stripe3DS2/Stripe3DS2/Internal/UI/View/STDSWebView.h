//
//  STDSWebView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSWebView : WKWebView

/**
 Convenience method that prepends the given HTML string with a CSP meta tag that disables external resource loading, and passes it to `loadHTMLString:baseURL:`.
 */
- (WKNavigation *)loadExternalResourceBlockingHTMLString:(NSString *)html;

@end

NS_ASSUME_NONNULL_END
