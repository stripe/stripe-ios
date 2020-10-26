//
//  STPSourcePoller.m
//  Stripe
//
//  Created by Ben Guo on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourcePoller.h"

#import "STPAPIClient+Private.h"
#import "STPAPIRequest.h"
#import "STPSource.h"
#import "StripeError.h"
#import "NSError+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const DefaultPollInterval = 1.5;
static NSTimeInterval const MaxPollInterval = 24;
// Stop polling after 5 minutes
static NSTimeInterval const MaxTimeout = 60*5;
// Stop polling after 5 consecutive non-200 responses
static NSTimeInterval const MaxRetries = 5;

@interface STPSourcePoller ()

@property (nonatomic, weak) STPAPIClient *apiClient;
@property (nonatomic) NSString *sourceID;
@property (nonatomic) NSString *clientSecret;
@property (nonatomic, copy) STPSourceCompletionBlock completion;
@property (nonatomic, nullable) STPSource *latestSource;
@property (nonatomic) NSTimeInterval pollInterval;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic, nullable) NSURLSessionDataTask *dataTask;
@property (nonatomic, nullable) NSTimer *timer;
@property (nonatomic) NSDate *startTime;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger requestCount;
@property (nonatomic) BOOL pollingPaused;
@property (nonatomic) BOOL pollingStopped;

@end

@implementation STPSourcePoller

- (instancetype)initWithAPIClient:(STPAPIClient *)apiClient
                     clientSecret:(NSString *)clientSecret
                         sourceID:(NSString *)sourceID
                          timeout:(NSTimeInterval)timeout
                       completion:(STPSourceCompletionBlock)completion {
    self = [super init];
    if (self) {
        _apiClient = apiClient;
        _sourceID = sourceID;
        _clientSecret = clientSecret;
        _completion = completion;
        _pollInterval = DefaultPollInterval;
        _timeout = timeout;
        _startTime = [NSDate date];
        _retryCount = 0;
        _requestCount = 0;
        _pollingPaused = NO;
        _pollingStopped = NO;
        [self pollAfter:0 lastError:nil];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(restartPolling)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(restartPolling)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(pausePolling)
                                   name:UIApplicationWillResignActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(pausePolling)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pollAfter:(NSTimeInterval)interval lastError:(nullable NSError *)error {
    NSTimeInterval totalTime = [[NSDate date] timeIntervalSinceDate:self.startTime];
    BOOL shouldTimeout = (self.requestCount > 0 &&
                          (totalTime >= MIN(self.timeout, MaxTimeout) || self.retryCount >= MaxRetries));
    if (!self.apiClient || shouldTimeout) {
        [self cleanupAndFireCompletionWithSource:self.latestSource
                                           error:error];
        return;
    }
    if (self.pollingPaused || self.pollingStopped) {
        return;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                  target:self
                                                selector:@selector(poll)
                                                userInfo:nil
                                                 repeats:NO];
}

- (void)poll {
    self.timer = nil;
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTaskID = UIBackgroundTaskInvalid;
    bgTaskID = [application beginBackgroundTaskWithExpirationHandler:^{
        self.dataTask = nil;
        [application endBackgroundTask:bgTaskID];
        bgTaskID = UIBackgroundTaskInvalid;
    }];
    self.dataTask = [self.apiClient retrieveSourceWithId:self.sourceID
                                            clientSecret:self.clientSecret
                                      responseCompletion:^(STPSource *source, NSHTTPURLResponse *response, NSError *error) {
                                          [self continueWithSource:source response:response error:error];
                                          self.requestCount++;
                                          self.dataTask = nil;
                                          [application endBackgroundTask:bgTaskID];
                                          bgTaskID = UIBackgroundTaskInvalid;
                                      }];
}

- (void)continueWithSource:(STPSource *)source
                  response:(NSHTTPURLResponse *)response
                     error:(NSError *)error {
    if (response) {
        NSUInteger status = response.statusCode;
        if (status >= 400 && status < 500) {
            // Don't retry requests that 4xx
            [self cleanupAndFireCompletionWithSource:self.latestSource
                                               error:error];
        } else if (status == 200) {
            self.pollInterval = DefaultPollInterval;
            self.retryCount = 0;
            self.latestSource = source;
            if ([self shouldContinuePollingSource:source]) {
                [self pollAfter:self.pollInterval lastError:nil];
            } else {
                [self cleanupAndFireCompletionWithSource:self.latestSource
                                                   error:nil];
            }
        } else {
            // Backoff and increment retry count
            self.pollInterval = MIN(self.pollInterval*2, MaxPollInterval);
            self.retryCount++;
            [self pollAfter:self.pollInterval lastError:error];
        }
    } else {
        // Retry if there's a connectivity error
        if (error.code == kCFURLErrorNotConnectedToInternet ||
            error.code == kCFURLErrorNetworkConnectionLost) {
            self.retryCount++;
            [self pollAfter:self.pollInterval lastError:error];
        } else {
            // Don't call completion if the request was cancelled
            if (error.code != kCFURLErrorCancelled) {
                [self cleanupAndFireCompletionWithSource:self.latestSource
                                                   error:error];
            }
            [self stopPolling];
        }
    }
}

- (BOOL)shouldContinuePollingSource:(nullable STPSource *)source {
    if (!source) {
        return NO;
    }
    return source.status == STPSourceStatusPending;
}

- (void)restartPolling {
    if (self.pollingStopped) {
        return;
    }
    self.pollingPaused = NO;
    if (!self.timer && !self.dataTask) {
        [self pollAfter:0 lastError:nil];
    }
}

// Pauses polling, without canceling the request in progress.
- (void)pausePolling {
    self.pollingPaused = YES;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)cleanupAndFireCompletionWithSource:(nullable STPSource *)source
                                     error:(nullable NSError *)error {
    if (!self.pollingStopped) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && !source) {
                self.completion(nil, [NSError stp_genericConnectionError]);
            } else {
                self.completion(source, error);
            }
        });
        [self stopPolling];
    }
}

// Stops polling and cancels the request in progress.
- (void)stopPolling {
    self.pollingStopped = YES;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (self.dataTask) {
        [self.dataTask cancel];
        self.dataTask = nil;
    }
}

@end

NS_ASSUME_NONNULL_END
