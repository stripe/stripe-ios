//
//  STPFileClient.m
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPFileClient.h"
#import "STPAPIClient.h"
#import "STPMultipartFormDataEncoder.h"
#import "STPMultipartFormDataPart.h"
#import "StripeError.h"
#import "STPDispatchFunctions.h"
#import "NSMutableURLRequest+Stripe.h"

static NSString * STPStripeFileUploadPath = @"https://uploads.stripe.com/v1/files";

@interface STPFileClient ()

@property (nonatomic, copy) NSString *publishableKey;
@property (nonatomic, readwrite) NSURLSession *urlSession;

+ (void)validateKey:(NSString *)publishableKey;

@end

@implementation STPFileClient

#pragma mark - Constructors

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[self alloc] init];
    });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithPublishableKey:[Stripe defaultPublishableKey]];
}

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        self.publishableKey = publishableKey;
        [[self class] validateKey:_publishableKey];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *auth = [@"Bearer " stringByAppendingString:_publishableKey];
        config.HTTPAdditionalHeaders = @{@"Authorization": auth};
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

#pragma mark - File Methods

- (void)uploadImage:(UIImage *)image purpose:(STPFilePurpose)purpose completion:(nullable STPFileCompletionBlock)completion {
    STPMultipartFormDataPart *purposePart = [[STPMultipartFormDataPart alloc] init];
    purposePart.name = @"purpose";
    purposePart.data = [[STPFile stringForPurpose:purpose] dataUsingEncoding:NSUTF8StringEncoding];
    
    STPMultipartFormDataPart *imagePart = [[STPMultipartFormDataPart alloc] init];
    imagePart.name = @"file";
    imagePart.filename = @"image.jpg";
    imagePart.contentType = @"image/jpeg";
    imagePart.data = UIImageJPEGRepresentation(image, 0.5);
    
    NSString *boundary = [STPMultipartFormDataEncoder generateBoundary];
    NSData *data = [STPMultipartFormDataEncoder multipartFormDataForParts:@[purposePart, imagePart] boundary:boundary];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:STPStripeFileUploadPath]];
    [request setHTTPMethod:@"POST"];
    [request stp_setMultipartFormData:data boundary:boundary];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable body, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *jsonDictionary = body ? [NSJSONSerialization JSONObjectWithData:body options:(NSJSONReadingOptions)kNilOptions error:NULL] : nil;
        STPFile *file = [STPFile decodedObjectFromAPIResponse:jsonDictionary];
        
        NSError *returnedError = [NSError stp_errorFromStripeResponse:jsonDictionary] ?: error;
        if ((!file || ![response isKindOfClass:[NSHTTPURLResponse class]]) && !returnedError) {
            returnedError = [NSError stp_genericFailedToParseResponseError];
        }
        
        if (!completion) return;
            
        stpDispatchToMainThreadIfNecessary(^{
            if (returnedError) {
                completion(nil, returnedError);
            } else {
                completion(file, nil);
            }
        });
    }] resume];
}

#pragma mark - Private Helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
+ (void)validateKey:(NSString *)publishableKey {
    NSCAssert(publishableKey != nil && ![publishableKey isEqualToString:@""],
              @"You must use a valid publishable key to upload a file. For more info, see https://stripe.com/docs/stripe.js");
    BOOL secretKey = [publishableKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key to upload a file, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js");
#ifndef DEBUG
    if ([publishableKey.lowercaseString hasPrefix:@"pk_test"]) {
        FAUXPAS_IGNORED_IN_METHOD(NSLogUsed);
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"ℹ️ You're using your Stripe testmode key. Make sure to use your livemode key when submitting to the App Store!");
        });
    }
#endif
}
#pragma clang diagnostic pop

@end
