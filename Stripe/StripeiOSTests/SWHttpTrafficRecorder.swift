//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
///********************************************************************************
/// Copyright 2015 Capital One Services, LLC
/// SPDX-License-Identifier: Apache-2.0
/// SPDX-Copyright: Copyright (c) Capital One Services, LLC
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///*********************************************************************************


////////////////////////////////////////////////////////////////////////////////

//  Created by Jinlian (Sunny) Wang on 8/23/15.

import Foundation

//! Project version number for SWHttpTrafficRecorder.
var SWHttpTrafficRecorderVersionNumber = 0.0
//! Project version string for SWHttpTrafficRecorder.
let SWHttpTrafficRecorderVersionString: [UInt8] = []
/// Recording formats that is supported by SWHttpTrafficRecorder.
enum SWHTTPTrafficRecordingFormat : Int {
    // Custom format when the recorder records a request through an optional createFileInCustomFormatBlock block.
    case custom = -1
    // For BodyOnly format, the recorder creates a recorded file for each request using only its response body. If it is a JSON response, the file uses .json extension. Otherwise, .txt extenion is used.
    case bodyOnly = 1
    // For Mocktail format, the recorder creates a recorded file for each request and its response in format that is defined by Mocktail framework at https://github.com/puls/objc-mocktail. The file uses .tail extension.
    case mocktail = 2
    // For HTTPMessage format, the recorder creates a recorded file for each request and its response in format can be deserialized into a CFHTTPMessageRef raw HTTP Message. 'curl -is' also outputs in this format.
    case httpMessage = 3
}

/// Error codes for SWHttpTrafficRecorder.
enum SWHttpTrafficRecorderError : Int {
    /// The specified path does not exist and cannot be created
    case pathFailedToCreate = 1
    /// The specified path was not writable
    case pathNotWritable
}

/// Recording progress that is reported by SWHttpTrafficRecorder at each phase of recording a request and its response.
enum SWHTTPTrafficRecordingProgressKind : Int {
    // A HTTP Request is received by the recorder.
    case received = 1
    // A HTTP Request is skipped by the recorder for recording.
    case skipped = 2
    // The recorder starts downloading the response for a request.
    case started = 3
    // The recorder finishes downloading the response for a request.
    case loaded = 4
    // The recorder finishes recording the response for a request.
    case recorded = 5
    // The recorder fails to download the response for a request for whatever reason.
    case failedToLoad = 6
    // The recorder fails to record the response for a request for whatever reason.
    case failedToRecord = 7
}

// The key in a recording progress info dictionary whose value indicates the current NSURLRequest that is being recorded.
let SWHTTPTrafficRecordingProgressRequestKey: String? = nil
// The key in a recording progress info dictionary whose value indicates the current NSHTTPURLResponse that is being recorded.
let SWHTTPTrafficRecordingProgressResponseKey: String? = nil
// The key in a recording progress info dictionary whose value indicates the current NSData response body that is being recorded.
let SWHTTPTrafficRecordingProgressBodyDataKey: String? = nil
// The key in a recording progress info dictionary whose value indicates the current file path that is used for the recorded file.
let SWHTTPTrafficRecordingProgressFilePathKey: String? = nil
// The key in a recording progress info dictionary whose value indicates the current recording format.
let SWHTTPTrafficRecordingProgressFileFormatKey: String? = nil
// The key in a recording progress info dictionary whose value indicates the NSErrror which fails the recording.
let SWHTTPTrafficRecordingProgressErrorKey: String? = nil
// The error domain for SWHttpTrafficRecorder.
let SWHttpTrafficRecorderErrorDomain: String? = nil
let SWHTTPTrafficRecordingProgressRequestKey = "REQUEST_KEY"
let SWHTTPTrafficRecordingProgressResponseKey = "RESPONSE_KEY"
let SWHTTPTrafficRecordingProgressBodyDataKey = "BODY_DATA_KEY"
let SWHTTPTrafficRecordingProgressFilePathKey = "FILE_PATH_KEY"
let SWHTTPTrafficRecordingProgressFileFormatKey = "FILE_FORMAT_KEY"
let SWHTTPTrafficRecordingProgressErrorKey = "ERROR_KEY"
let SWHttpTrafficRecorderErrorDomain = "RECORDER_ERROR_DOMAIN"
////////////////////////////////////////////////////////////////////////////////
// MARK: - Private Protocol Class


private let SWRecordingLProtocolHandledKey = "SWRecordingLProtocolHandledKey"

/// An optional delegate SWHttpTrafficRecorder uses to report its recording progress.
@objc protocol SWHttpTrafficRecordingProgressDelegate: NSObjectProtocol {
    /// Delegate method to be called by the recorder to update its current progress.
    ///  - Parameters:
    ///   - currentProgress: The current progress of the recording.
    ///    - info: A recording progress info dictionary where its values (including a request object, its response, response body data, file path, recording format and NSError) can be retrieved through different keys. The available values depend on the current progress.
    func updateRecordingProgress(_ currentProgress: SWHTTPTrafficRecordingProgressKind, userInfo info: [AnyHashable : Any]?)
}

/// An SWHttpTrafficRecorder lets you intercepts the http requests made by an application and records their responses in a specified format. There are three built-in formats supported: ResponseBodyOnly, Mocktail and HTTPMessage. These formats are widely used by various mocking/stubbing frameworks such as Mocktail(https://github.com/puls/objc-mocktail), OHHTTPStubs(https://github.com/AliSoftware/OHHTTPStubs/tree/master/OHHTTPStubs), Nocilla(https://github.com/luisobo/Nocilla), etc. You can also use it to monitor the traffic for debugging purpose.
class SWHttpTrafficRecorder: NSObject {
    ///  A Boolean value which indicates whether the recording is recording traffic.
    private(set) var isRecording = false
    ///  A Enum value which indicates the format the recording is using to record traffic.
    var recordingFormat: SWHTTPTrafficRecordingFormat!
    ///  A Dictionary containing Regex/Token pairs for replacement in response data
    var replacementDict: [AnyHashable : Any]?
    ///  The delegate where the recording progress are reported.
    var progressDelegate: SWHttpTrafficRecordingProgressDelegate?
    ///  The optional block (if provided) to be applied to every request to determine whether the request shall be recorded by the recorder. It takes a NSURLRequest as parameter and returns a Boolean value that indicates whether the request shall be recorded.
    var recordingTestBlock: ((_ request: URLRequest?) -> Bool)?
    ///  The optional block (if provided) to be applied to every request to determine whether the response body shall be base64 encodes before recording. It takes a NSURLRequest as parameter and returns a Boolean value that indicates whether the response body shall be base64 encoded.
    var base64TestBlock: ((_ request: URLRequest?, _ response: URLResponse?) -> Bool)?
    ///  The optional block (if provided) to be applied to every request to determine what file name is to be used while creating the recorded file. It takes a NSURLRequest and a default name that is generated by the recorder as parameters and returns a NSString value which is used as filename while creating the recorded file.
    var fileNamingBlock: ((_ request: URLRequest?, _ response: URLResponse?, _ defaultName: String?) -> String)?
    ///  The optional block (if provided) to be applied to every request to determine what regular expression is to be used while creating a recorded file of Mocktail format. It takes a NSURLRequest and a default regular expression pattern that is generated by the recorder as parameters and returns a NSString value which is used as the regular expression pattern while creating the recorded file.
    var urlRegexPatternBlock: ((_ request: URLRequest?, _ defaultPattern: String?) -> String)?
    ///  The optional block (if provided) to be applied to every request to create the recorded file when the recording format is custom. It takes a NSURLRequest, its response, a body data and a filePath as parameters and be expected to create the recorded file at the filePath.
    var createFileInCustomFormatBlock: ((_ request: URLRequest?, _ response: URLResponse?, _ bodyData: Data?, _ filePath: String?) -> String)?
    private var recordingPath: String?
    private var fileNo = 0
    private var fileCreationQueue: OperationQueue?
    private var sessionConfig: URLSessionConfiguration?
    private var runTimeStamp = 0

    private var _fileExtensionMapping: [AnyHashable : Any]?
    private var fileExtensionMapping: [AnyHashable : Any]? {
        if _fileExtensionMapping == nil {
            _fileExtensionMapping = [
                "application/json": "json",
                "image/png": "png",
                "image/jpeg": "jpg",
                "image/gif": "gif",
                "image/bmp": "bmp",
                "text/plain": "txt",
                "text/css": "css",
                "text/html": "html",
                "application/javascript": "js",
                "text/javascript": "js",
                "application/xml": "xml",
                "text/xml": "xml",
                "image/tiff": "tiff",
                "image/x-tiff": "tiff"
            ]
        }
        return _fileExtensionMapping
    }

    /// Returns the shared recorder object.
    static let shared = {
        var shared = self.init()
        shared?.isRecording = false
        shared?.fileNo = 0
        shared?.fileCreationQueue = OperationQueue()
        shared?.runTimeStamp = 0
        shared?.recordingFormat = .mocktail
        return shared
    }()

    class func shared() -> Self {
        // [Swiftify] `dispatch_once()` call was converted to the initializer of the `shared` variable
        return shared
    }

    ///  Method to start recording using default path.
    func startRecording() -> Bool {
        return try? self.startRecording(atPath: nil, for: nil)
    }

    ///  Method to start recording and saves recorded files at a specified location.
    ///  - Parameters:
    ///   - path: The path where recorded files are saved.
    ///    - error: An out value that returns any error encountered while accessing the recordingPath. Returns an NSError object if any error; otherwise returns nil.
    func startRecording(atPath recordingPath: String?) throws {
        return try? self.startRecording(atPath: recordingPath, for: nil)
    }

    ///  Method to start recording and saves recorded files at a specified location using given session configuration.
    ///  - Parameters:
    ///   - recordingPath: The path where recorded files are saved.
    ///    - sessionConfig: The NSURLSessionConfiguration which will be modified.
    ///    - error: An out value that returns any error encountered while accessing the recordingPath. Returns an NSError object if any error; otherwise returns nil.
    func startRecording(atPath recordingPath: String?, for sessionConfig: URLSessionConfiguration?) throws {
        if !isRecording {
            if let recordingPath {
                self.recordingPath = recordingPath
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: recordingPath) {
                    var bError: Error?
                    try fileManager.createDirectory(atPath: recordingPath, withIntermediateDirectories: true, attributes: nil)
                    if false {
                        if error != nil {
                            if let bError {
                                error = Error(domain: SWHttpTrafficRecorderErrorDomain, code: SWHttpTrafficRecorderError.pathFailedToCreate.rawValue, userInfo: [
                                    NSLocalizedDescriptionKey: "Path '\(recordingPath)' does not exist and error while creating it.",
                                    NSUnderlyingErrorKey: bError
                                ])
                            }
                        }
                        return false
                    }
                } else if !fileManager.isWritableFile(atPath: recordingPath) {
                    if error != nil {
                        error = Error(domain: SWHttpTrafficRecorderErrorDomain, code: SWHttpTrafficRecorderError.pathNotWritable.rawValue, userInfo: [
                            NSLocalizedDescriptionKey: "Path '\(recordingPath)' is not writable."
                        ])
                    }
                    return false
                }
            } else {
                self.recordingPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).map(\.path)[0]
            }

            fileNo = 0
            runTimeStamp = Int(Date.timeIntervalSinceReferenceDate)
        }
        if let sessionConfig {
            self.sessionConfig = sessionConfig
            var mutableProtocols: NSMutableOrderedSet?
            if let protocolClasses = sessionConfig.protocolClasses {
                mutableProtocols = NSMutableOrderedSet(array: protocolClasses)
            }
            mutableProtocols?.insertObject(SWRecordingProtocol.self, at: 0)
            sessionConfig?.protocolClasses = mutableProtocols?.array as? [AnyClass]
        } else {
            URLProtocol.registerClass(SWRecordingProtocol.self)
        }

        isRecording = true

        return true
    }

    ///  Method to stop recording.
    func stopRecording() {
        if isRecording {
            if sessionConfig != nil {
                var mutableProtocols = sessionConfig?.protocolClasses
                mutableProtocols?.removeAll { $0 as AnyObject === SWRecordingProtocol.self as AnyObject }
                sessionConfig?.protocolClasses = mutableProtocols
                sessionConfig = nil
            } else {
                URLProtocol.unregisterClass(SWRecordingProtocol.self)
            }
        }
        isRecording = false
    }

    func increaseFileNo() -> Int {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return fileNo += 1
    }
}

class SWRecordingProtocol: NSURLProtocol, NSURLSessionDataDelegate {
    private var dataTask: URLSessionDataTask?
    private var mutableData: Data?
    private var response: URLResponse?
    private var session: URLSession?

    // MARK: - NSURLProtocol overrides

    class func canInit(with request: URLRequest) -> Bool {
        let isHTTP = (request.url?.scheme == "https") || (request.url?.scheme == "http")
        if URLProtocol.property(forKey: SWRecordingLProtocolHandledKey, in: request) != nil || !isHTTP {
            return false
        }

        self.updateRecorderProgressDelegate(.received, userInfo: [
            SWHTTPTrafficRecordingProgressRequestKey: request
        ])

        let testBlock: ((_ request: URLRequest?) -> Bool)? = SWHttpTrafficRecorder.shared().recordingTestBlock
        var canInit = true
        if let testBlock {
            canInit = testBlock(request)
        }
        if !canInit {
            if let request {
                self.updateRecorderProgressDelegate(.skipped, userInfo: [
                    SWHTTPTrafficRecordingProgressRequestKey: request
                ])
            }
        }
        return canInit
    }

    class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    func startLoading() {
        let newRequest = request as? NSMutableURLRequest
        if let newRequest {
            URLProtocol.setProperty(NSNumber(value: true), forKey: SWRecordingLProtocolHandledKey, in: newRequest)
        }

        updateRecorderProgressDelegate(.started, userInfo: [
            SWHTTPTrafficRecordingProgressRequestKey: request
        ])

        if let aSessionConfig = SWHttpTrafficRecorder.shared().sessionConfig {
            session = URLSession(
                configuration: aSessionConfig,
                delegate: self,
                delegateQueue: nil)
        }
        if let newRequest {
            dataTask = session?.dataTask(with: newRequest)
        }
        dataTask?.resume()
    }

    func stopLoading() {
        dataTask?.cancel()
        mutableData = nil
    }

    // MARK: - NSURLConnectionDelegate

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        self.response = response
        mutableData = Data()
        completionHandler(NSURLSessionResponseAllow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)

        mutableData?.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let data = mutableData?.copy()

        if let error {
            client?.urlProtocol(self, didFailWithError: error)

            updateRecorderProgressDelegate(
                .failedToLoad,
                userInfo: [
                    SWHTTPTrafficRecordingProgressRequestKey: self.request,
                    SWHTTPTrafficRecordingProgressErrorKey: error
                ])

            return
        }

        client?.urlProtocolDidFinishLoading(self)

        let response = self.response as? HTTPURLResponse
        let request = task.currentRequest

        if let request, let response, let data {
            updateRecorderProgressDelegate(
                .loaded,
                userInfo: [
                    SWHTTPTrafficRecordingProgressRequestKey: request,
                    SWHTTPTrafficRecordingProgressResponseKey: response,
                    SWHTTPTrafficRecordingProgressBodyDataKey: data
                ])
        }

        let path = getFilePath(request, response: response)
        let format = SWHttpTrafficRecorder.shared().recordingFormat
        if format == .bodyOnly {
            createBodyOnlyFile(with: request, response: response, data: data, atFilePath: path)
        } else if format == .mocktail {
            createMocktailFile(with: request, response: response, data: data, atFilePath: path)
        } else if format == .httpMessage {
            createHTTPMessageFile(with: request, response: response, data: data, atFilePath: path)
        } else if format == .custom && SWHttpTrafficRecorder.shared().createFileInCustomFormatBlock != nil {
            SWHttpTrafficRecorder.shared().createFileInCustomFormatBlock?(request, response, data, path)
        } else {
            print(String(format: "File format: %ld is not supported.", format.rawValue))
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        if let response {
            client.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        }
        completionHandler(request)
    }

    // MARK: - File Creation Utility Methods

    func getFileName(_ request: URLRequest?, response: HTTPURLResponse?) -> String? {
        var fileName = request?.url?.lastPathComponent

        if fileName == nil || isNotValidFileName(fileName) {
            fileName = "Mocktail"
        }

        fileName = String(format: "%@_%lu_%d", fileName ?? "", UInt(SWHttpTrafficRecorder.shared().runTimeStamp), SWHttpTrafficRecorder.shared().increaseFileNo())

        fileName = URL(fileURLWithPath: fileName ?? "").appendingPathExtension(getFileExtension(request, response: response) ?? "").path

        let fileNamingBlock: ((_ request: URLRequest?, _ response: URLResponse?, _ defaultName: String?) -> String)? = SWHttpTrafficRecorder.shared().fileNamingBlock

        if let fileNamingBlock {
            fileName = fileNamingBlock(request, response, fileName)
        }
        return fileName
    }

    func isNotValidFileName(_ fileName: String?) -> Bool {
        return false
    }

    func getFilePath(_ request: URLRequest?, response: HTTPURLResponse?) -> String? {
        let recordingPath = SWHttpTrafficRecorder.shared().recordingPath
        let filePath = URL(fileURLWithPath: recordingPath ?? "").appendingPathComponent(getFileName(request, response: response) ?? "").path

        return filePath
    }

    func getFileExtension(_ request: URLRequest?, response: HTTPURLResponse?) -> String? {
        let format = SWHttpTrafficRecorder.shared().recordingFormat
        if format == .bodyOnly {
            // Based on http://blog.ablepear.com/2010/08/how-to-get-file-extension-for-mime-type.html, we may be able to get the file extension from mime type. Use a fixed mapping for simpilicity for now unless there is a need later on
            return SWHttpTrafficRecorder.shared().fileExtensionMapping?[response?.mimeType ?? ""] ?? "unknown"
        } else if format == .mocktail {
            return "tail"
        } else if format == .httpMessage {
            return "response"
        }

        return "unknown"
    }

    func toBase64Body(_ request: URLRequest?, andResponse response: HTTPURLResponse?) -> Bool {
        if SWHttpTrafficRecorder.shared().base64TestBlock != nil {
            return SWHttpTrafficRecorder.shared().base64TestBlock?(request, response)
        }
        return response?.mimeType?.hasPrefix("image") ?? false
    }

    func doBase64(_ bodyData: Data?, request: URLRequest?, response: HTTPURLResponse?) -> Data? {
        let toBase64 = toBase64Body(request, andResponse: response)
        if toBase64 && bodyData != nil {
            return bodyData?.base64EncodedData(options: [])
        } else {
            return bodyData
        }
    }

    func doJSONPrettyPrint(_ bodyData: Data?, request: URLRequest?, response: HTTPURLResponse?) -> Data? {
        var bodyData = bodyData
        if (response?.mimeType == "application/json") && bodyData != nil {
            var error: Error?
            var json: Any?
            do {
                if let bodyData {
                    json = try JSONSerialization.jsonObject(with: bodyData, options: [])
                }
            } catch let e {
                error = e
            }
            if json != nil && error == nil {
                do {
                    if let json {
                        bodyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    }
                } catch {
                    if let error {
                        print("Somehow the content is not a json though the mime type is json: \(error)")
                    }
                }
            } else {
                if let error {
                    print("Somehow the content is not a json though the mime type is json: \(error)")
                }
            }
        }
        return bodyData
    }

    func createFile(at filePath: String?, using data: Data?, completionHandler: @escaping (_ created: Bool) -> Void) {
        var created = false
        let creationOp = BlockOperation(block: {
            created = FileManager.default.createFile(atPath: filePath ?? "", contents: data, attributes: [.protectionKey : FileProtectionType.complete])
        })
        creationOp.completionBlock = {
            completionHandler(created)
        }
        SWHttpTrafficRecorder.shared().fileCreationQueue?.addOperation(creationOp)
    }

    // MARK: - BodyOnly File Creation

    func createBodyOnlyFile(with request: URLRequest?, response: HTTPURLResponse?, data: Data?, atFilePath filePath: String?) {
        var data = data
        data = doJSONPrettyPrint(data, request: request, response: response)

        var userInfo: [String : URLRequest?]?
        if let request, let response, let data {
            userInfo = [
                SWHTTPTrafficRecordingProgressRequestKey: request,
                SWHTTPTrafficRecordingProgressResponseKey: response,
                SWHTTPTrafficRecordingProgressBodyDataKey: data,
                SWHTTPTrafficRecordingProgressFileFormatKey: NSNumber(value: SWHTTPTrafficRecordingFormat.bodyOnly.rawValue),
                SWHTTPTrafficRecordingProgressFilePathKey: filePath ?? ""
            ]
        }
        createFile(at: filePath, using: data) { [self] created in
            updateRecorderProgressDelegate(created ? .recorded : .failedToRecord, userInfo: userInfo)
        }
    }

    // MARK: - Mocktail File Creation

    func createMocktailFile(with request: URLRequest?, response: HTTPURLResponse?, data: Data?, atFilePath filePath: String?) {
        var data = data
        var tail = ""

        tail += "\(request?.httpMethod ?? "")\n"
        tail += "\(getURLRegexPattern(request) ?? "")\n"
        tail += String(format: "%ld\n", Int(response?.statusCode ?? 0))
        tail += "\(response?.mimeType ?? "")\(toBase64Body(request, andResponse: response) ? ";base64" : "")\n"
        let headerKeys = (response?.allHeaderFields as NSDictionary?).keyEnumerator()
        if let headerKeys {
            for key in headerKeys {
                guard let key = key as? String else {
                    continue
                }
                tail += "\(key): \((response?.allHeaderFields[key] as? String) ?? "")\n"
            }
        }

        tail += "\n"

        data = doBase64(data, request: request, response: response)

        data = doJSONPrettyPrint(data, request: request, response: response)

        data = replaceRegexWithTokens(in: data)

        if let data {
            tail += "\((data != nil ? String(data: data, encoding: .utf8) : "") ?? "")"
        }

        var userInfo: [String : URLRequest?]?
        if let request, let response, let data {
            userInfo = [
                SWHTTPTrafficRecordingProgressRequestKey: request,
                SWHTTPTrafficRecordingProgressResponseKey: response,
                SWHTTPTrafficRecordingProgressBodyDataKey: data,
                SWHTTPTrafficRecordingProgressFileFormatKey: NSNumber(value: SWHTTPTrafficRecordingFormat.mocktail.rawValue),
                SWHTTPTrafficRecordingProgressFilePathKey: filePath ?? ""
            ]
        }
        createFile(at: filePath, using: tail.data(using: .utf8)) { [self] created in
            updateRecorderProgressDelegate(created ? .recorded : .failedToRecord, userInfo: userInfo)
        }
    }

    func replaceRegexWithTokens(in data: Data?) -> Data? {
        var data = data
        let recorder = SWHttpTrafficRecorder.shared()
        if recorder.replacementDict == nil {
            return data
        } else {
            var dataString: String?
            if let data {
                dataString = String(data: data, encoding: .utf8)
            }
            for key in recorder.replacementDict ?? [:] {
                guard let key = key as? String else {
                    continue
                }
                if recorder.replacementDict?[key] is NSRegularExpression {
                    dataString = recorder.replacementDict?[key]?.stringByReplacingMatches(in: dataString ?? "", options: [], range: NSRange(location: 0, length: dataString?.count ?? 0), withTemplate: key)
                }
            }
            data = dataString?.data(using: .utf8)
            return data
        }
    }

    func getURLRegexPattern(_ request: URLRequest?) -> String? {
        var urlPattern = request?.url?.path
        if request?.url?.query != nil {
            let queryArray = request?.url?.query?.components(separatedBy: "&")
            var processedQueryArray = [AnyHashable](repeating: 0, count: queryArray?.count ?? 0)
            for part in queryArray ?? [] {
                var urlRegex: NSRegularExpression?
                do {
                    urlRegex = try NSRegularExpression(pattern: "(.*)=(.*)", options: .caseInsensitive)
                } catch {
                }
                let newPart = urlRegex?.stringByReplacingMatches(in: part, options: [], range: NSRange(location: 0, length: part.count), withTemplate: "$1=.*")
                processedQueryArray.append(newPart ?? "")
            }
            urlPattern = "\(request?.url?.path ?? "")\\?\(processedQueryArray.joined(separator: "&"))"
        }

        let urlRegexPatternBlock: ((_ request: URLRequest?, _ defaultPattern: String?) -> String)? = SWHttpTrafficRecorder.shared().urlRegexPatternBlock

        if let urlRegexPatternBlock {
            urlPattern = urlRegexPatternBlock(request, urlPattern)
        }

        urlPattern = (urlPattern ?? "") + "$"

        return urlPattern
    }

    // MARK: - HTTP Message File Creation

    func createHTTPMessageFile(with request: URLRequest?, response: HTTPURLResponse?, data: Data?, atFilePath filePath: String?) {
        var dataString = ""

        dataString += "\(statusLine(from: response) ?? "")\n"

        let headers = response?.allHeaderFields
        for key in headers ?? [:] {
            guard let key = key as? String else {
                continue
            }
            if let header = headers?[key] {
                dataString += "\(key): \(header)\n"
            }
        }

        dataString += "\n"

        var responseData: Data?
        if let aData = dataString.data(using: .utf8) {
            responseData = Data(data: aData)
        }
        if let data {
            responseData?.append(data)
        }

        var userInfo: [String : URLRequest?]?
        if let request, let response, let data {
            userInfo = [
                SWHTTPTrafficRecordingProgressRequestKey: request,
                SWHTTPTrafficRecordingProgressResponseKey: response,
                SWHTTPTrafficRecordingProgressBodyDataKey: data,
                SWHTTPTrafficRecordingProgressFileFormatKey: NSNumber(value: SWHTTPTrafficRecordingFormat.httpMessage.rawValue),
                SWHTTPTrafficRecordingProgressFilePathKey: filePath ?? ""
            ]
        }

        createFile(at: filePath, using: responseData) { [self] created in
            updateRecorderProgressDelegate(created ? .recorded : .failedToRecord, userInfo: userInfo)
        }
    }

    func statusLine(from response: HTTPURLResponse?) -> String? {
        let message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, CFIndex(response?.statusCode ?? 0), nil, kCFHTTPVersion1_1) as? CFHTTPMessage
        var statusLine: String?
        if let message {
            statusLine = CFHTTPMessageCopyResponseStatusLine(message) as? String
        }

        return statusLine
    }

    // MARK: - Recording Progress

    class func updateRecorderProgressDelegate(_ progress: SWHTTPTrafficRecordingProgressKind, userInfo info: [AnyHashable : Any]?) {
        let recorder = SWHttpTrafficRecorder.shared()
        if recorder.progressDelegate != nil && recorder.progressDelegate?.responds(to: #selector(SWHttpTrafficRecordingProgressDelegate.updateRecordingProgress(_:userInfo:))) ?? false {
            recorder.progressDelegate?.updateRecordingProgress(progress, userInfo: info)
        }
    }
}
