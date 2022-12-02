/***********************************************************************************
 * Copyright 2015 Capital One Services, LLC
 * SPDX-License-Identifier: Apache-2.0
 * SPDX-Copyright: Copyright (c) Capital One Services, LLC
 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 
 * http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ***********************************************************************************/


////////////////////////////////////////////////////////////////////////////////

//  Created by Jinlian (Sunny) Wang on 8/23/15.

#import "SWHttpTrafficRecorder.h"

NSString * const SWHTTPTrafficRecordingProgressRequestKey   = @"REQUEST_KEY";
NSString * const SWHTTPTrafficRecordingProgressResponseKey  = @"RESPONSE_KEY";
NSString * const SWHTTPTrafficRecordingProgressBodyDataKey  = @"BODY_DATA_KEY";
NSString * const SWHTTPTrafficRecordingProgressFilePathKey  = @"FILE_PATH_KEY";
NSString * const SWHTTPTrafficRecordingProgressFileFormatKey= @"FILE_FORMAT_KEY";
NSString * const SWHTTPTrafficRecordingProgressErrorKey     = @"ERROR_KEY";

NSString * const SWHttpTrafficRecorderErrorDomain           = @"RECORDER_ERROR_DOMAIN";

@interface SWHttpTrafficRecorder()
@property(nonatomic, assign, readwrite) BOOL isRecording;
@property(nonatomic, strong) NSString *recordingPath;
@property(nonatomic, assign) int fileNo;
@property(nonatomic, strong) NSOperationQueue *fileCreationQueue;
@property(nonatomic, strong) NSURLSessionConfiguration *sessionConfig;
@property(nonatomic, assign) NSUInteger runTimeStamp;
@property(nonatomic, strong) NSDictionary *fileExtensionMapping;
@end

@interface SWRecordingProtocol : NSURLProtocol @end

@implementation SWHttpTrafficRecorder

+ (instancetype)sharedRecorder
{
    static SWHttpTrafficRecorder *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = self.new;
        shared.isRecording = NO;
        shared.fileNo = 0;
        shared.fileCreationQueue = [[NSOperationQueue alloc] init];
        shared.runTimeStamp = 0;
        shared.recordingFormat = SWHTTPTrafficRecordingFormatMocktail;
    });
    return shared;
}

- (BOOL)startRecording{
    return [self startRecordingAtPath:nil forSessionConfiguration:nil error:nil];
}

- (BOOL)startRecordingAtPath:(NSString *)recordingPath error:(NSError **) error {
    return [self startRecordingAtPath:recordingPath forSessionConfiguration:nil error:error];
}

- (BOOL)startRecordingAtPath:(NSString *)recordingPath forSessionConfiguration:(NSURLSessionConfiguration *)sessionConfig error:(NSError **) error {
    if(!self.isRecording){
        if(recordingPath){
            self.recordingPath = recordingPath;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if(![fileManager fileExistsAtPath:recordingPath]){
                NSError *bError = nil;
                if(![fileManager createDirectoryAtPath:recordingPath withIntermediateDirectories:YES attributes:nil error:&bError]){
                    if(error){
                        *error = [NSError errorWithDomain:SWHttpTrafficRecorderErrorDomain code:SWHttpTrafficRecorderErrorPathFailedToCreate userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Path '%@' does not exist and error while creating it.", recordingPath], NSUnderlyingErrorKey: bError}];
                    }
                    return NO;
                }
            } else if(![fileManager isWritableFileAtPath:recordingPath]){
                if (error){
                    *error = [NSError errorWithDomain:SWHttpTrafficRecorderErrorDomain code:SWHttpTrafficRecorderErrorPathNotWritable userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Path '%@' is not writable.", recordingPath]}];
                }
                return NO;
            }
        } else {
            self.recordingPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        }

        self.fileNo = 0;
        self.runTimeStamp = (NSUInteger)[NSDate timeIntervalSinceReferenceDate];
    }
    if(sessionConfig){
        self.sessionConfig = sessionConfig;
        NSMutableOrderedSet *mutableProtocols = [[NSMutableOrderedSet alloc] initWithArray:sessionConfig.protocolClasses];
        [mutableProtocols insertObject:[SWRecordingProtocol class] atIndex:0];
        sessionConfig.protocolClasses = [mutableProtocols array];
    }
    else {
        [NSURLProtocol registerClass:[SWRecordingProtocol class]];
    }

    self.isRecording = YES;
    
    return YES;
}

- (void)stopRecording{
    if(self.isRecording){
        if(self.sessionConfig) {
            NSMutableArray *mutableProtocols = [[NSMutableArray alloc] initWithArray:self.sessionConfig.protocolClasses];
            [mutableProtocols removeObject:[SWRecordingProtocol class]];
            self.sessionConfig.protocolClasses = mutableProtocols;
            self.sessionConfig = nil;
        }
        else {
            [NSURLProtocol unregisterClass:[SWRecordingProtocol class]];
        }
    }
    self.isRecording = NO;
}

- (int)increaseFileNo{
    @synchronized(self) {
        return self.fileNo++;
    }
}

- (NSDictionary *)fileExtensionMapping{
    if(!_fileExtensionMapping){
        _fileExtensionMapping = @{
                                  @"application/json": @"json", @"image/png": @"png", @"image/jpeg" : @"jpg",
                                  @"image/gif": @"gif", @"image/bmp": @"bmp", @"text/plain": @"txt",
                                  @"text/css": @"css", @"text/html": @"html", @"application/javascript": @"js",
                                  @"text/javascript": @"js", @"application/xml": @"xml", @"text/xml": @"xml",
                                  @"image/tiff": @"tiff", @"image/x-tiff": @"tiff"
                                  };
    }
    return _fileExtensionMapping;
}

@end


////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private Protocol Class


static NSString * const SWRecordingLProtocolHandledKey = @"SWRecordingLProtocolHandledKey";

@interface SWRecordingProtocol () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSURLSession *session;

@end


@implementation SWRecordingProtocol

#pragma mark - NSURLProtocol overrides

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"https"] || [request.URL.scheme isEqualToString:@"http"];
    if ([NSURLProtocol propertyForKey:SWRecordingLProtocolHandledKey inRequest:request] || !isHTTP) {
        return NO;
    }
    
    [self updateRecorderProgressDelegate:SWHTTPTrafficRecordingProgressReceived userInfo:@{SWHTTPTrafficRecordingProgressRequestKey: request}];
    
    BOOL(^testBlock)(NSURLRequest *request) = [SWHttpTrafficRecorder sharedRecorder].recordingTestBlock;
    BOOL canInit = YES;
    if(testBlock){
        canInit = testBlock(request);
    }
    if(!canInit){
        [self updateRecorderProgressDelegate:SWHTTPTrafficRecordingProgressSkipped userInfo:@{SWHTTPTrafficRecordingProgressRequestKey: request}];
    }
    return canInit;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:SWRecordingLProtocolHandledKey inRequest:newRequest];
    
    [self.class updateRecorderProgressDelegate:SWHTTPTrafficRecordingProgressStarted userInfo:@{SWHTTPTrafficRecordingProgressRequestKey: self.request}];
    
    self.session = [NSURLSession sessionWithConfiguration:SWHttpTrafficRecorder.sharedRecorder.sessionConfig
                                                 delegate:self
                                            delegateQueue:nil];
    self.dataTask = [self.session dataTaskWithRequest:newRequest];
    [self.dataTask resume];
}

- (void) stopLoading {
    [self.dataTask cancel];
    self.mutableData = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    
    [self.mutableData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSData *data = [self.mutableData copy];
    
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
        
        [self.class updateRecorderProgressDelegate:SWHTTPTrafficRecordingProgressFailedToLoad
                                          userInfo:@{SWHTTPTrafficRecordingProgressRequestKey: self.request,
                                                     SWHTTPTrafficRecordingProgressErrorKey: error
                                                     }];

        return;
    }
    
    [self.client URLProtocolDidFinishLoading:self];
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.response;
    NSURLRequest *request = (NSURLRequest*)task.currentRequest;
    
    [self.class updateRecorderProgressDelegate:SWHTTPTrafficRecordingProgressLoaded
                                      userInfo:@{SWHTTPTrafficRecordingProgressRequestKey: request,
                                                 SWHTTPTrafficRecordingProgressResponseKey: response,
                                                 SWHTTPTrafficRecordingProgressBodyDataKey: data
                                                 }];
    
    NSString *path = [self getFilePath:request response:response];
    SWHTTPTrafficRecordingFormat format = [SWHttpTrafficRecorder sharedRecorder].recordingFormat;
    if(format == SWHTTPTrafficRecordingFormatBodyOnly){
        [self createBodyOnlyFileWithRequest:request response:response data:data atFilePath:path];
    } else if(format == SWHTTPTrafficRecordingFormatMocktail){
        [self createMocktailFileWithRequest:request response:response data:data atFilePath:path];
    } else if(format == SWHTTPTrafficRecordingFormatHTTPMessage){
        [self createHTTPMessageFileWithRequest:request response:response data:data atFilePath:path];
    } else if(format == SWHTTPTrafficRecordingFormatCustom && [SWHttpTrafficRecorder sharedRecorder].createFileInCustomFormatBlock != nil){
        [SWHttpTrafficRecorder sharedRecorder].createFileInCustomFormatBlock(request, response, data, path);
    } else {
        NSLog(@"File format: %ld is not supported.", (long)format);
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (response != nil) {
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    completionHandler(request);
}


#pragma mark - File Creation Utility Methods

-(NSString *)getFileName:(NSURLRequest *)request response:(NSHTTPURLResponse *)response{
    NSString *fileName = [request.URL lastPathComponent];
    
    if(!fileName || [self isNotValidFileName: fileName]){
        fileName = @"Mocktail";
    }

    fileName = [NSString stringWithFormat:@"%@_%lu_%d", fileName, (unsigned long)[SWHttpTrafficRecorder sharedRecorder].runTimeStamp, [[SWHttpTrafficRecorder sharedRecorder] increaseFileNo]];
    
    fileName = [fileName stringByAppendingPathExtension:[self getFileExtension:request response:response]];
    
    NSString *(^fileNamingBlock)(NSURLRequest *request, NSURLResponse *response, NSString *defaultName) = [SWHttpTrafficRecorder sharedRecorder].fileNamingBlock;
    
    if(fileNamingBlock){
        fileName = fileNamingBlock(request, response, fileName);
    }
    return fileName;
}

-(BOOL)isNotValidFileName:(NSString*) fileName{
    return NO;
}

-(NSString *)getFilePath:(NSURLRequest *)request response:(NSHTTPURLResponse *)response{
    NSString *recordingPath = [SWHttpTrafficRecorder sharedRecorder].recordingPath;
    NSString *filePath = [recordingPath stringByAppendingPathComponent:[self getFileName:request response:response]];

    return filePath;
}

-(NSString *)getFileExtension:(NSURLRequest *)request response:(NSHTTPURLResponse *)response{
    SWHTTPTrafficRecordingFormat format = [SWHttpTrafficRecorder sharedRecorder].recordingFormat;
    if(format == SWHTTPTrafficRecordingFormatBodyOnly){
        /* Based on http://blog.ablepear.com/2010/08/how-to-get-file-extension-for-mime-type.html, we may be able to get the file extension from mime type. Use a fixed mapping for simpilicity for now unless there is a need later on */
        return [SWHttpTrafficRecorder sharedRecorder].fileExtensionMapping[response.MIMEType] ?: @"unknown";
    } else if(format == SWHTTPTrafficRecordingFormatMocktail){
        return @"tail";
    } else if(format == SWHTTPTrafficRecordingFormatHTTPMessage){
        return @"response";
    }
    
    return @"unknown";
}

-(BOOL)toBase64Body:(NSURLRequest *)request andResponse:(NSHTTPURLResponse *)response{
    if([SWHttpTrafficRecorder sharedRecorder].base64TestBlock){
        return [SWHttpTrafficRecorder sharedRecorder].base64TestBlock(request, response);
    }
    return [response.MIMEType hasPrefix:@"image"];
}

-(NSData *)doBase64:(NSData *)bodyData request: (NSURLRequest*)request response:(NSHTTPURLResponse*)response{
    BOOL toBase64 = [self toBase64Body:request andResponse:response];
    if(toBase64 && bodyData){
        return [bodyData base64EncodedDataWithOptions:0];
    } else {
        return bodyData;
    }
}

-(NSData *)doJSONPrettyPrint:(NSData *)bodyData request: (NSURLRequest*)request response:(NSHTTPURLResponse*)response{
    if([response.MIMEType isEqualToString:@"application/json"] && bodyData)
    {
        NSError *error;
        id json = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&error];
        if(json && !error){
            bodyData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&error];
            if(error){
                NSLog(@"Somehow the content is not a json though the mime type is json: %@", error);
            }
        } else {
            NSLog(@"Somehow the content is not a json though the mime type is json: %@", error);
        }
    }
    return bodyData;
}

-(void)createFileAt:(NSString *)filePath usingData:(NSData *)data completionHandler:(void(^)(BOOL created))completionHandler{
    __block BOOL created = NO;
    NSBlockOperation* creationOp = [NSBlockOperation blockOperationWithBlock: ^{
        created = [NSFileManager.defaultManager createFileAtPath:filePath contents:data attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey]];
    }];
    creationOp.completionBlock = ^{
        completionHandler(created);
    };
    [[SWHttpTrafficRecorder sharedRecorder].fileCreationQueue addOperation:creationOp];
}

#pragma mark - BodyOnly File Creation

-(void)createBodyOnlyFileWithRequest:(NSURLRequest*)request response:(NSHTTPURLResponse*)response data:(NSData*)data atFilePath:(NSString *)filePath
{
    data = [self doJSONPrettyPrint:data request:request response:response];
    
    NSDictionary *userInfo = @{SWHTTPTrafficRecordingProgressRequestKey: request,
                               SWHTTPTrafficRecordingProgressResponseKey: response,
                               SWHTTPTrafficRecordingProgressBodyDataKey: data,
                               SWHTTPTrafficRecordingProgressFileFormatKey: @(SWHTTPTrafficRecordingFormatBodyOnly),
                               SWHTTPTrafficRecordingProgressFilePathKey: filePath
                               };
    [self createFileAt:filePath usingData:data completionHandler:^(BOOL created) {
        [self.class updateRecorderProgressDelegate:(created ? SWHTTPTrafficRecordingProgressRecorded : SWHTTPTrafficRecordingProgressFailedToRecord) userInfo:userInfo];
    }];
}

#pragma mark - Mocktail File Creation

-(void)createMocktailFileWithRequest:(NSURLRequest*)request response:(NSHTTPURLResponse*)response data:(NSData*)data atFilePath:(NSString *)filePath
{
    NSMutableString *tail = NSMutableString.new;
    
    [tail appendFormat:@"%@\n", request.HTTPMethod];
    [tail appendFormat:@"%@\n", [self getURLRegexPattern:request]];
    [tail appendFormat:@"%ld\n", (long)response.statusCode];
    [tail appendFormat:@"%@%@\n", response.MIMEType, [self toBase64Body:request andResponse:response] ? @";base64": @""];
    NSEnumerator *headerKeys = [response.allHeaderFields keyEnumerator];
    for (NSString *key in headerKeys) {
        [tail appendFormat:@"%@: %@\n", key, (NSString*)[response.allHeaderFields objectForKey:key]];
    }
    
    [tail appendString:@"\n"];
    
    data = [self doBase64:data request:request response:response];
    
    data = [self doJSONPrettyPrint:data request:request response:response];
    
    data = [self replaceRegexWithTokensInData:data];
    
    [tail appendFormat:@"%@", data ? [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding] : @""];
    
    NSDictionary *userInfo = @{SWHTTPTrafficRecordingProgressRequestKey: request,
                               SWHTTPTrafficRecordingProgressResponseKey: response,
                               SWHTTPTrafficRecordingProgressBodyDataKey: data,
                               SWHTTPTrafficRecordingProgressFileFormatKey: @(SWHTTPTrafficRecordingFormatMocktail),
                               SWHTTPTrafficRecordingProgressFilePathKey: filePath
                               };
    [self createFileAt:filePath usingData:[tail dataUsingEncoding:NSUTF8StringEncoding] completionHandler:^(BOOL created) {
        [self.class updateRecorderProgressDelegate:(created ? SWHTTPTrafficRecordingProgressRecorded : SWHTTPTrafficRecordingProgressFailedToRecord) userInfo: userInfo];
    }];
}

-(NSData *)replaceRegexWithTokensInData: (NSData *) data {
    SWHttpTrafficRecorder *recorder = [SWHttpTrafficRecorder sharedRecorder];
    if(![recorder replacementDict]) {
        return data;
    }
    else {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        for(NSString *key in [recorder replacementDict]) {
            if([[[recorder replacementDict] objectForKey: key] isKindOfClass:[NSRegularExpression class]]) {
                dataString = [[[recorder replacementDict] objectForKey:key] stringByReplacingMatchesInString:dataString options:0 range:NSMakeRange(0, [dataString length]) withTemplate:key];
            }
        }
        data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        return data;
    }
}

-(NSString *)getURLRegexPattern:(NSURLRequest *)request{
    NSString *urlPattern = request.URL.path;
    if(request.URL.query){
        NSArray *queryArray = [request.URL.query componentsSeparatedByString:@"&"];
        NSMutableArray *processedQueryArray = [[NSMutableArray alloc] initWithCapacity:queryArray.count];
        for (NSString *part in queryArray) {
            NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:@"(.*)=(.*)" options:NSRegularExpressionCaseInsensitive error:nil];
            NSString *newPart = [urlRegex stringByReplacingMatchesInString:part options:0 range:NSMakeRange(0, part.length) withTemplate:@"$1=.*"];
            [processedQueryArray addObject:newPart];
        }
        urlPattern = [NSString stringWithFormat:@"%@\\?%@", request.URL.path, [processedQueryArray componentsJoinedByString:@"&"]];
    }
    
    NSString *(^urlRegexPatternBlock)(NSURLRequest *request, NSString *defaultPattern) = [SWHttpTrafficRecorder sharedRecorder].urlRegexPatternBlock;
    
    if(urlRegexPatternBlock){
        urlPattern = urlRegexPatternBlock(request, urlPattern);
    }
    
    urlPattern = [urlPattern stringByAppendingString:@"$"];
    
    return urlPattern;
}

#pragma mark - HTTP Message File Creation

-(void)createHTTPMessageFileWithRequest:(NSURLRequest*)request response:(NSHTTPURLResponse*)response data:(NSData*)data atFilePath:(NSString *)filePath
{
    NSMutableString *dataString = NSMutableString.new;
    
    [dataString appendFormat:@"%@\n", [self statusLineFromResponse:response]];
     
    NSDictionary *headers = response.allHeaderFields;
    for(NSString *key in headers){
        [dataString appendFormat:@"%@: %@\n", key, headers[key]];
    }
    
    [dataString appendString:@"\n"];
    
    NSMutableData *responseData = [NSMutableData dataWithData:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
    [responseData appendData:data];
    
    NSDictionary *userInfo = @{SWHTTPTrafficRecordingProgressRequestKey: request,
                               SWHTTPTrafficRecordingProgressResponseKey: response,
                               SWHTTPTrafficRecordingProgressBodyDataKey: data,
                               SWHTTPTrafficRecordingProgressFileFormatKey: @(SWHTTPTrafficRecordingFormatHTTPMessage),
                               SWHTTPTrafficRecordingProgressFilePathKey: filePath
                               };
    
    [self createFileAt:filePath usingData:responseData completionHandler:^(BOOL created) {
        [self.class updateRecorderProgressDelegate:(created ? SWHTTPTrafficRecordingProgressRecorded : SWHTTPTrafficRecordingProgressFailedToRecord) userInfo:userInfo];
    }];
}

- (NSString *)statusLineFromResponse:(NSHTTPURLResponse*)response{
    CFHTTPMessageRef message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, [response statusCode], NULL, kCFHTTPVersion1_1);
    NSString *statusLine = (__bridge_transfer NSString *)CFHTTPMessageCopyResponseStatusLine(message);
    CFRelease(message);
    return statusLine;
}

#pragma mark - Recording Progress 

+ (void)updateRecorderProgressDelegate:(SWHTTPTrafficRecordingProgressKind)progress userInfo:(NSDictionary *)info{
    SWHttpTrafficRecorder *recorder = [SWHttpTrafficRecorder sharedRecorder];
    if(recorder.progressDelegate && [recorder.progressDelegate respondsToSelector:@selector(updateRecordingProgress:userInfo:)]){
        [recorder.progressDelegate updateRecordingProgress:progress userInfo:info];
    }
}

@end
