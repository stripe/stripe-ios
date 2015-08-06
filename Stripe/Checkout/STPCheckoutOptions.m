//
//  STPCheckoutOptions.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/6/14.
//

#import "Stripe.h"
#import "STPCheckoutOptions.h"
#import "STPColorUtils.h"

@implementation STPCheckoutOptions

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        _publishableKey = publishableKey;
        _companyName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
        _purchaseCurrency = @"USD";
    }
    return self;
}

- (instancetype)init {
    return [self initWithPublishableKey:[Stripe defaultPublishableKey]];
}

- (NSString *)stringifiedJSONRepresentation {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    if (self.publishableKey) {
        values[@"publishableKey"] = self.publishableKey;
    }
    if (self.logoURL) {
        values[@"logoURL"] = [self.logoURL absoluteString];
    }
    if (self.logoColor) {
        values[@"logoColor"] = [STPColorUtils hexCodeForColor:self.logoColor];
    }
    if (self.companyName) {
        values[@"companyName"] = self.companyName;
    }
    if (self.purchaseDescription) {
        values[@"purchaseDescription"] = self.purchaseDescription;
    }
    if (self.purchaseAmount != 0) {
        values[@"purchaseAmount"] = @(self.purchaseAmount);
    }
    if (self.customerEmail) {
        values[@"customerEmail"] = self.customerEmail;
    }
    if (self.purchaseLabel) {
        values[@"purchaseLabel"] = self.purchaseLabel;
    }
    if (self.purchaseCurrency) {
        values[@"purchaseCurrency"] = [self.purchaseCurrency uppercaseString];
    }
    if (self.enableRememberMe) {
        values[@"enableRememberMe"] = self.enableRememberMe;
    }
    if (self.enablePostalCode) {
        values[@"enablePostalCode"] = self.enablePostalCode;
    }
    if (self.requireBillingAddress) {
        values[@"requireBillingAddress"] = self.requireBillingAddress;
    }

    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:values options:0 error:nil] encoding:NSUTF8StringEncoding];
}

- (void)setLogoImage:(STP_IMAGE_CLASS * __nullable)logoImage {
    _logoImage = logoImage;
    NSString *base64;
#if TARGET_OS_IPHONE
    NSData *pngRepresentation = UIImagePNGRepresentation(logoImage);
    if ([pngRepresentation respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        base64 = [pngRepresentation base64EncodedStringWithOptions:0];
    }
#else
    NSData *imageData = [logoImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    imageData = [imageRep representationUsingType:NSPNGFileType
                                       properties:@{NSImageCompressionFactor: @1.0}];
    base64 = [imageData base64EncodedStringWithOptions:0];
#endif
    if (base64) {
        NSString *dataURLString = [NSString stringWithFormat:@"data:png;base64,%@", base64];
        self.logoURL = [NSURL URLWithString:dataURLString];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(__unused NSZone *)zone {
    STPCheckoutOptions *options = [[[self class] alloc] init];
    options.publishableKey = self.publishableKey;
    options.logoURL = self.logoURL;
    options.logoImage = self.logoImage;
    options.logoColor = self.logoColor;
    options.companyName = self.companyName;
    options.purchaseDescription = self.purchaseDescription;
    options.purchaseAmount = self.purchaseAmount;
    options.customerEmail = self.customerEmail;
    options.purchaseLabel = self.purchaseLabel;
    options.purchaseCurrency = self.purchaseCurrency;
    options.enableRememberMe = self.enableRememberMe;
    options.enablePostalCode = self.enablePostalCode;
    options.requireBillingAddress = self.requireBillingAddress;
    return options;
}

@end
