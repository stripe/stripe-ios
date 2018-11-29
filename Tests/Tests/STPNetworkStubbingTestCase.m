//
//  STPNetworkStubbingTestCase.m
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/24/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPNetworkStubbingTestCase.h"
#import "STPAPIClient+Private.h"
#import <SWHttpTrafficRecorder/SWHttpTrafficRecorder.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHHTTPStubs+Mocktail.h>

@implementation STPNetworkStubbingTestCase

- (void)setUp {
    [super setUp];
    
    // [self name] returns a string like `-[STPMyTestCase testThing]` - this transforms it into the recorded path `recorded_network_traffic/STPMyTestCase/testThing`.
    NSMutableArray *rawComponents = [[[self name] componentsSeparatedByString:@" "] mutableCopy];
    NSCAssert(rawComponents.count == 2, @"Invalid format received from XCTest#name: %@", [self name]);
    NSMutableArray *components = [NSMutableArray array];
    [rawComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, __unused BOOL *stop) {
        components[idx] = [[component componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    }];
    
    NSString *testClass = components[0];
    NSString *testMethod = components[1];
    NSString *relativePath = [@"recorded_network_traffic" stringByAppendingPathComponent:[testClass stringByAppendingPathComponent:testMethod]];
    
    if (self.recordingMode) {
#if TARGET_OS_SIMULATOR
#else
        // Must be in the simulator, so that we can write recorded traffic into the repo.
        NSCAssert(NO, @"Tests executed in recording mode must be run in the simulator.");
#endif
        NSURLSessionConfiguration *config = [STPAPIClient sharedUrlSessionConfiguration];
        SWHttpTrafficRecorder *recorder = [SWHttpTrafficRecorder sharedRecorder];
        
        // Creates filenames like `post_v1_tokens_0.tail`.
        __block int count = 0;
        [recorder setFileNamingBlock:^NSString *(NSURLRequest *request, __unused NSURLResponse *response, __unused NSString *defaultName) {
            NSString *method = [request.HTTPMethod lowercaseString];
            NSString *urlPath = [request.URL.path stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
            NSString *fileName = [NSString stringWithFormat:@"%@%@_%d", method, urlPath, count];
            fileName = [fileName stringByAppendingPathExtension:@"tail"];
            count++;
            return fileName;
        }];
        
        // The goal is for `basePath` to be e.g. `~/stripe/stripe-ios/Tests`
        // A little gross/hardcoded (but it works fine); feel free to improve this...
        NSString *testDirectoryName = @"stripe-ios/Tests";
        NSString *basePath = [NSString stringWithFormat:@"%s", __FILE__];
        while (![basePath hasSuffix:testDirectoryName]) {
            NSCAssert([basePath containsString:testDirectoryName], @"Not in a subdirectory of %@: %s", testDirectoryName, __FILE__);
            basePath = [basePath stringByDeletingLastPathComponent];
        }
        
        NSString *recordingPath = [basePath stringByAppendingPathComponent:relativePath];
        // Delete existing stubs
        [[NSFileManager defaultManager] removeItemAtPath:recordingPath error:nil];
        NSError *recordingError;
        BOOL success = [[SWHttpTrafficRecorder sharedRecorder] startRecordingAtPath:recordingPath forSessionConfiguration:config error:&recordingError];
        NSCAssert(success, @"Error recording requests: %@", recordingError);
        
        // Make sure to fail, to remind ourselves to turn this off
        __weak typeof(self) weakself = self;
        [self addTeardownBlock:^{
            // Like XCTFail, but avoiding a retain cycle
            _XCTPrimitiveFail(weakself, @"Network traffic for %@ has been recorded - re-run with self.recordingMode = NO for this test to succeed", [weakself name]);
        }];
    } else {
        // Stubs are evaluated in the reverse order that they are added, so if the network is hit and no other stub is matched, raise an exception
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(__unused NSURLRequest * _Nonnull request) {
            return YES;
        } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
            NSCAssert(NO, @"Attempted to hit the live network at %@", request.URL.path);
            return nil;
        }];
        
        // Note: in order to make this work, the stub files (end in .tail) must be added to the test bundle during Build Phases/Copy Resources Step.
        NSBundle *bundle = [NSBundle bundleForClass:self.class];
        NSURL *url = [bundle URLForResource:relativePath withExtension:nil];
        if (url) {
            NSError *stubError;
            [OHHTTPStubs stubRequestsUsingMocktailsAtPath:relativePath inBundle:bundle error:&stubError];
            NSCAssert(!stubError, @"Error stubbing requests: %@", stubError);
        } else {
            NSLog(@"No stubs found - all network access will raise an exception.");
        }
    }
}

- (void)tearDown {
    [super tearDown];
    // Additional calls to `setFileNamingBlock` will be ignored if you don't do this
    [[SWHttpTrafficRecorder sharedRecorder] stopRecording];
    
    // Don't accidentally keep any stubs around during the next test run
    [OHHTTPStubs removeAllStubs];
}

@end
