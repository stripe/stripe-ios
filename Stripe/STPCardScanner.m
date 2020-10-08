//
//  STPCardScanner.m
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPCardScanner.h"
#import "STPAnalyticsClient.h"

#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>

#import "STPCardValidator+Private.h"
#import "STPPaymentMethodCardParams.h"
#import "STPStringUtils.h"
#import "STPLocalizationUtils.h"
#import "StripeError.h"

// The number of successful scans required for both card number and expiration date before returning a result.
static const NSUInteger kSTPCardScanningMinimumValidScans = 2;
// If no expiration date is found, we'll return a result after this many successful scans.
static const NSUInteger kSTPCardScanningMaxValidScans = 3;
// Once one successful scan is found, we'll stop scanning after this many seconds.
static const NSTimeInterval kSTPCardScanningTimeout = 1.0;

NSString * const STPCardScannerErrorDomain = @"STPCardScannerErrorDomain";

@interface STPCardScanner () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) id<STPCardScannerDelegate>delegate;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong, readwrite) dispatch_queue_t captureSessionQueue;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;

@property (nonatomic, strong) VNRecognizeTextRequest *textRequest;

@property (atomic) BOOL isScanning;
@property (atomic) BOOL didTimeout;
@property (atomic) BOOL timeoutStarted;

@property (atomic) UIDeviceOrientation _stp_deviceOrientation;
@property (atomic) AVCaptureVideoOrientation videoOrientation;
@property (atomic) CGImagePropertyOrientation textOrientation;

@property (nonatomic) CGRect regionOfInterest;

@property (nonatomic) NSCountedSet<NSString*> *detectedNumbers;
@property (nonatomic) NSCountedSet<NSString*> *detectedExpirations;

@property (nonatomic) NSDate *startTime;

@end

@implementation STPCardScanner

#pragma mark Public

+ (BOOL)cardScanningAvailable {
    // Always allow in tests:
    if (NSClassFromString(@"XCTest") != nil) {
        return YES;
    }

    // iOS will kill the app if it tries to request the camera without an NSCameraUsageDescription
    static BOOL cameraHasUsageDescription = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSCameraUsageDescription"] != nil) {
            cameraHasUsageDescription = YES;
        }
    });
    return cameraHasUsageDescription;
}

+ (NSError *)stp_cardScanningError {
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: STPLocalizedString(@"To scan your card, you'll need to allow access to your camera in Settings.", @"Error when the user hasn't allowed the current app to access the camera when scanning a payment card. 'Settings' is the localized name of the iOS Settings app."),
                               STPErrorMessageKey: @"The camera couldn't be used."
                               };
    return [[NSError alloc] initWithDomain:STPCardScannerErrorDomain code:STPCardScannerErrorCameraNotAvailable userInfo:userInfo];
}

- (instancetype)initWithDelegate:(id<STPCardScannerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.captureSessionQueue = dispatch_queue_create("com.stripe.CardScanning.CaptureSessionQueue", nil);
        self.deviceOrientation = [[UIDevice currentDevice] orientation];
    }
    return self;
}

- (void)dealloc {
    if (self.isScanning) {
        [self.captureDevice unlockForConfiguration];
        [self.captureSession stopRunning];
    }
}

- (void)start {
    if (self.isScanning) {
        return;
    }
    [[STPAnalyticsClient sharedClient] addClassToProductUsageIfNecessary:[self class]];
    self.startTime = [NSDate date];
    
    self.isScanning = YES;
    self.didTimeout = NO;
    self.timeoutStarted = NO;
    
    dispatch_async(_captureSessionQueue, ^{
        self.detectedNumbers = [[NSCountedSet alloc] initWithCapacity:5];
        self.detectedExpirations = [[NSCountedSet alloc] initWithCapacity:5];
        [self setupCamera];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cameraView.captureSession = self.captureSession;
            self.cameraView.videoPreviewLayer.connection.videoOrientation = self.videoOrientation;
        });
    });
}

- (void)stop {
    [self stopWithError:nil];
}

- (void)stopWithError:(nullable NSError *)error {
    if (self.isScanning) {
        [self finishWithParams:nil error:error];
    }
}

#pragma mark Setup

- (void)setupCamera {
    __weak typeof(self) weakSelf = self;
    self.textRequest = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf.isScanning) {
            return;
        }
        if (error) {
            [strongSelf stopWithError:[STPCardScanner stp_cardScanningError]];
            return;
        }
        [strongSelf processVNRequest:request];
    }];
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    self.captureDevice = captureDevice;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
    
    NSError *deviceInputError;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&deviceInputError];
    if (deviceInputError) {
        [self stopWithError:[STPCardScanner stp_cardScanningError]];
        return;
    }
    
    if ([self.captureSession canAddInput:deviceInput]) {
        [self.captureSession addInput:deviceInput];
    } else {
        [self stopWithError:[STPCardScanner stp_cardScanningError]];
        return;
    }
    
    self.videoDataOutputQueue = dispatch_queue_create("com.stripe.CardScanning.VideoDataOutputQueue", nil);
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
    
    // This is the recommended pixel buffer format for Vision:
    [self.videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
    
    if ([self.captureSession canAddOutput:self.videoDataOutput]) {
        [self.captureSession addOutput:self.videoDataOutput];
    } else {
        [self stopWithError:[STPCardScanner stp_cardScanningError]];
        return;
    }
    
    // This improves recognition quality, but means the VideoDataOutput buffers won't match what we're seeing on screen.
    [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    
    [self.captureSession startRunning];
    
    NSError *lockError;
    [self.captureDevice lockForConfiguration:&lockError];
    if (lockError == nil) {
        self.captureDevice.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
    }
}

#pragma mark Processing

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (!self.isScanning) {
        return;
    }
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (pixelBuffer == nil) {
        return;
    }
    self.textRequest.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    self.textRequest.usesLanguageCorrection = NO;
    self.textRequest.regionOfInterest = self.regionOfInterest;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer orientation:self.textOrientation options:@{}];
    __unused NSError *requestError;
    [handler performRequests:@[self.textRequest] error:&requestError];
}

- (void)processVNRequest:(VNRequest * _Nonnull)request {
    NSMutableArray *allNumbers = [[NSMutableArray alloc] init];
    for (VNRecognizedTextObservation *observation in request.results) {
        NSArray *candidates = [observation topCandidates:5];
        NSString *topCandidate = [[candidates firstObject] string];
        if ([[STPCardValidator sanitizedNumericStringForString:topCandidate] length] >= 4) {
            [allNumbers addObject:topCandidate];
        }
        for (VNRecognizedText *recognizedText in candidates) {
            NSString *possibleNumber = [STPCardValidator sanitizedNumericStringForString:recognizedText.string];
            if ([possibleNumber length] < 4) {
                continue; // This probably isn't something we're interested in, so don't bother processing it.
            }
            
            // First strategy: We check if Vision sent us a number in a group on its own. If that fails, we'll try
            // to catch it later when we iterate over all the numbers.
            if ([STPCardValidator validationStateForNumber:possibleNumber validatingCardBrand:YES] == STPCardValidationStateValid) {
                [self addDetectedNumber:possibleNumber];
            } else if ([possibleNumber length] >= 4 && [possibleNumber length] <= 6 && [STPStringUtils stringMayContainExpirationDate:recognizedText.string]) {
                // Try to parse anything that looks like an expiration date.
                NSString *expirationString = [STPStringUtils expirationDateStringFromString:recognizedText.string];
                NSString *sanitizedExpiration = [STPCardValidator sanitizedNumericStringForString:expirationString];
                NSString *month = [sanitizedExpiration substringToIndex:2];
                NSString *year = [sanitizedExpiration substringFromIndex:2];

                // Ignore expiration dates 10+ years in the future, as they're likely to be incorrect recognitions
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSDateComponents *currentDateComponents = [calendar components:NSCalendarUnitYear fromDate:[NSDate date]];
                NSInteger maxYear = ([currentDateComponents year] % 100) + 10;
                
                if ([STPCardValidator validationStateForExpirationYear:year inMonth:month] == STPCardValidationStateValid && [year integerValue] < maxYear) {
                    [self addDetectedExpiration:sanitizedExpiration];
                }
            }
        }
    }
    // Second strategy: We look for consecutive groups of 4/4/4/4 or 4/6/5
    // Vision is sending us groups like ["1234 565", "1234 1"], so we'll normalize these into groups with spaces:
    NSArray *allGroups = [[allNumbers componentsJoinedByString:@" "] componentsSeparatedByString:@" "];
    for (NSInteger i = 0; i < (NSInteger)[allGroups count] - 3; i++) {
        NSString *string1 = allGroups[i];
        NSString *string2 = allGroups[i + 1];
        NSString *string3 = allGroups[i + 2];
        NSString *string4 = @"";
        if (i + 3 < (NSInteger)[allGroups count]) {
            string4 = allGroups[i + 3];
        }
        // Then we'll go through each group and build a potential match:
        NSString *potentialCardString = [NSString stringWithFormat:@"%@%@%@%@", string1, string2, string3, string4];
        NSString *potentialAmexString = [NSString stringWithFormat:@"%@%@%@", string1, string2, string3];
        
        // Then we'll add valid matches. It's okay if we add a number a second time after doing so above, as the success of that first pass means it's more likely to be a good match.
        if ([STPCardValidator validationStateForNumber:potentialCardString validatingCardBrand:YES] == STPCardValidationStateValid) {
            [self addDetectedNumber:potentialCardString];
        } else if ([STPCardValidator validationStateForNumber:potentialAmexString validatingCardBrand:YES] == STPCardValidationStateValid) {
            [self addDetectedNumber:potentialAmexString];
        }
    }
}


- (void)addDetectedNumber:(NSString *)number {
    [self.detectedNumbers addObject:number];

    // Set a timeout: If we don't get enough scans in the next 1 second, we'll use the best option we have.
    if (!self.timeoutStarted) {
        self.timeoutStarted = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf.cameraView playSnapshotAnimation];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSTPCardScanningTimeout * NSEC_PER_SEC)), self.videoDataOutputQueue, ^{
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.isScanning) {
                strongSelf.didTimeout = YES;
                [strongSelf finishIfReady];
            }
        });
    }
    
    if ([_detectedNumbers countForObject:number] >= kSTPCardScanningMinimumValidScans) {
        [self finishIfReady];
    }
}

- (void)addDetectedExpiration:(NSString *)expiration {
    [self.detectedExpirations addObject:expiration];
    if ([self.detectedExpirations countForObject:expiration] >= kSTPCardScanningMinimumValidScans) {
        [self finishIfReady];
    }
}

#pragma mark Completion

- (void)finishIfReady {
    if (!self.isScanning) {
        return;
    }
    NSCountedSet<NSString *> *detectedNumbers = self.detectedNumbers;
    NSCountedSet<NSString *> *detectedExpirations = self.detectedExpirations;
    
    NSString *topNumber = [[detectedNumbers.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSUInteger c1 = [detectedNumbers countForObject:obj1];
        NSUInteger c2 = [detectedNumbers countForObject:obj2];
        if (c1 < c2) {
            return NSOrderedAscending;
        } else if (c1 > c2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }] lastObject];
    NSString *topExpiration = [[detectedExpirations.allObjects sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSUInteger c1 = [detectedExpirations countForObject:obj1];
        NSUInteger c2 = [detectedExpirations countForObject:obj2];
        if (c1 < c2) {
            return NSOrderedAscending;
        } else if (c1 > c2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }] lastObject];
    
    if (self.didTimeout ||
        (([detectedNumbers countForObject:topNumber] >= kSTPCardScanningMinimumValidScans) && ([detectedExpirations countForObject:topExpiration] >= kSTPCardScanningMinimumValidScans))
        || ([detectedNumbers countForObject:topNumber] >= kSTPCardScanningMaxValidScans)
        ) {
        STPPaymentMethodCardParams *params = [[STPPaymentMethodCardParams alloc] init];
        params.number = topNumber;
        if (topExpiration) {
            params.expMonth = @([[topExpiration substringToIndex:2] integerValue]);
            params.expYear = @([[topExpiration substringFromIndex:2] integerValue]);
        }
        [self finishWithParams:params error:nil];
    }
}

- (void)finishWithParams:(STPPaymentMethodCardParams *)params error:(NSError *)error {
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.startTime];
    self.isScanning = NO;
    [self.captureDevice unlockForConfiguration];
    [self.captureSession stopRunning];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (params == nil) {
            [[STPAnalyticsClient sharedClient] logCardScanCancelledWithDuration:duration];
        } else {
            [[STPAnalyticsClient sharedClient] logCardScanSucceededWithDuration:duration];
        }

        self.cameraView.captureSession = nil;
        [self.delegate cardScanner:self didFinishWithCardParams:params error:error];
    });
}

#pragma mark Orientation

- (void)setDeviceOrientation:(UIDeviceOrientation)newDeviceOrientation {
    self._stp_deviceOrientation = newDeviceOrientation;
    
    // This is an optimization for portrait mode: The card will be centered in the screen,
    // so we can ignore the top and bottom. We'll use the whole frame in landscape.
    CGRect kSTPCardScanningScreenCenter = CGRectMake(0, (CGFloat)0.3, 1, (CGFloat)0.4);

    // iOS camera image data is returned in LandcapeLeft orientation by default. We'll flip it as needed:
    switch (newDeviceOrientation) {
        case UIDeviceOrientationPortraitUpsideDown:
            self.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            self.textOrientation = kCGImagePropertyOrientationLeft;
            self.regionOfInterest = kSTPCardScanningScreenCenter;
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            self.textOrientation = kCGImagePropertyOrientationUp;
            self.regionOfInterest = CGRectMake(0, 0, 1, 1);
            break;
        case UIDeviceOrientationLandscapeRight:
            self.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            self.textOrientation = kCGImagePropertyOrientationDown;
            self.regionOfInterest = CGRectMake(0, 0, 1, 1);
            break;
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationUnknown:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
            self.videoOrientation = AVCaptureVideoOrientationPortrait;
            self.textOrientation = kCGImagePropertyOrientationRight;
            self.regionOfInterest = kSTPCardScanningScreenCenter;
            break;
    }
    self.cameraView.videoPreviewLayer.connection.videoOrientation = _videoOrientation;
}

- (UIDeviceOrientation)deviceOrientation {
    return self._stp_deviceOrientation;
}

@end
