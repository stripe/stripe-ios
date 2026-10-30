/***********************************************************************************
 * Copyright 2015 Capital One Services, LLC
 * SPDX-License-Identifier: Apache-2.0
 * SPDX-Copyright: Copyright (c) Capital One Services, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 ***********************************************************************************/

//
//  SWHttpTrafficRecorder.swift
//  StripePaymentsTestUtils
//
//  Created by Jinlian (Sunny) Wang on 8/23/15.
//
//  A Swift port of the parts of SWHttpTrafficRecorder that the Stripe tests use: recording
//  network traffic into Mocktail (`.tail`) files that OHHTTPStubs can replay.
//

import Foundation

public final class SWHttpTrafficRecorder {
    public enum RecorderError: Error {
        /// The specified path does not exist and cannot be created.
        case pathFailedToCreate(path: String, underlyingError: Error)
        /// The specified path was not writable.
        case pathNotWritable(path: String)
    }

    public static let shared = SWHttpTrafficRecorder()

    /// Whether the recorder is recording traffic.
    public private(set) var isRecording = false
    /// Whether to follow HTTP redirects. Defaults to `true`.
    public var followRedirects = true
    /// Returns the name of the file to record a request into.
    public var fileNamingBlock: ((URLRequest, URLResponse, String) -> String)?
    /// Returns the URL regex pattern written into the recorded file for a request.
    public var urlRegexPatternBlock: ((URLRequest, String) -> String)?
    /// Transforms the request body written into the recorded file.
    public var postBodyTransformBlock: ((URLRequest, String) -> String)?

    fileprivate var recordingPath = ""
    fileprivate var sessionConfig: URLSessionConfiguration?
    fileprivate let fileCreationQueue = OperationQueue()
    private var fileNumber = 0
    private var runTimestamp = 0
    private let lock = NSLock()

    private init() {}

    /// Starts recording the traffic of sessions created with `sessionConfig` into Mocktail files at `recordingPath`.
    public func startRecording(atPath recordingPath: String, for sessionConfig: URLSessionConfiguration) throws {
        if !isRecording {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: recordingPath) {
                do {
                    try fileManager.createDirectory(atPath: recordingPath, withIntermediateDirectories: true)
                } catch {
                    throw RecorderError.pathFailedToCreate(path: recordingPath, underlyingError: error)
                }
            } else if !fileManager.isWritableFile(atPath: recordingPath) {
                throw RecorderError.pathNotWritable(path: recordingPath)
            }
            self.recordingPath = recordingPath
            fileNumber = 0
            runTimestamp = Int(Date.timeIntervalSinceReferenceDate)
        }
        self.sessionConfig = sessionConfig
        var protocolClasses = sessionConfig.protocolClasses ?? []
        protocolClasses.removeAll { $0 == SWRecordingProtocol.self }
        protocolClasses.insert(SWRecordingProtocol.self, at: 0)
        sessionConfig.protocolClasses = protocolClasses
        isRecording = true
    }

    /// Stops recording traffic.
    public func stopRecording() {
        if isRecording, let sessionConfig {
            sessionConfig.protocolClasses = sessionConfig.protocolClasses?.filter { $0 != SWRecordingProtocol.self }
            self.sessionConfig = nil
        }
        isRecording = false
    }

    fileprivate func nextFileNumber() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let number = fileNumber
        fileNumber += 1
        return number
    }

    fileprivate func filePath(for request: URLRequest, response: URLResponse) -> String {
        var fileName = "\(request.url?.lastPathComponent ?? "Mocktail")_\(runTimestamp)_\(nextFileNumber())"
        fileName = (fileName as NSString).appendingPathExtension("tail") ?? fileName
        if let fileNamingBlock {
            fileName = fileNamingBlock(request, response, fileName)
        }
        return (recordingPath as NSString).appendingPathComponent(fileName)
    }
}

private let SWRecordingProtocolHandledKey = "SWRecordingLProtocolHandledKey"

private final class SWRecordingProtocol: URLProtocol, URLSessionDataDelegate {
    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    private var response: URLResponse?
    private var session: URLSession?

    override static func canInit(with request: URLRequest) -> Bool {
        let isHTTP = request.url?.scheme == "https" || request.url?.scheme == "http"
        return isHTTP && URLProtocol.property(forKey: SWRecordingProtocolHandledKey, in: request) == nil
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let newRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return
        }
        URLProtocol.setProperty(true, forKey: SWRecordingProtocolHandledKey, in: newRequest)
        let session = URLSession(
            configuration: SWHttpTrafficRecorder.shared.sessionConfig ?? .default,
            delegate: self,
            delegateQueue: nil
        )
        self.session = session
        dataTask = session.dataTask(with: newRequest as URLRequest)
        dataTask?.resume()
    }

    override func stopLoading() {
        dataTask?.cancel()
        receivedData = Data()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.response = response
        receivedData = Data()
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        receivedData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        client?.urlProtocolDidFinishLoading(self)
        guard let response = response as? HTTPURLResponse, let request = task.currentRequest else {
            return
        }
        let path = SWHttpTrafficRecorder.shared.filePath(for: request, response: response)
        print("Recording request: \(request.url?.absoluteString ?? "")")
        print("Recording response code: \(response.statusCode)")
        print("To path: \(path)")
        createMocktailFile(request: request, response: response, data: receivedData, filePath: path)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(SWHttpTrafficRecorder.shared.followRedirects ? request : nil)
    }

    // MARK: - Mocktail file creation

    private func createMocktailFile(request: URLRequest, response: HTTPURLResponse, data: Data, filePath: String) {
        let isBase64 = response.mimeType?.hasPrefix("image") ?? false
        var tail = ""
        tail += "\(request.httpMethod ?? "")\n"
        tail += "\(urlRegexPattern(for: request))\n"
        tail += "\(response.statusCode)\n"
        tail += "\(response.mimeType ?? "")\(isBase64 ? ";base64" : "")\n"
        for (key, value) in response.allHeaderFields {
            tail += "\(key): \(value)\n"
        }
        if let postBody = postBodyString(for: request) {
            tail += "X-Stripe-Mock-Request: \(postBody)\n"
        }
        tail += "\n"
        var body = isBase64 ? data.base64EncodedData() : data
        if response.mimeType == "application/json",
           let json = try? JSONSerialization.jsonObject(with: body),
           let prettyPrinted = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            body = prettyPrinted
        }
        tail += String(data: body, encoding: .utf8) ?? ""

        let fileData = tail.data(using: .utf8)
        SWHttpTrafficRecorder.shared.fileCreationQueue.addOperation {
            FileManager.default.createFile(
                atPath: filePath,
                contents: fileData,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }
    }

    private func postBodyString(for request: URLRequest) -> String? {
        guard var postBody = request.value(forHTTPHeaderField: "X-Stripe-Mock-Request"), !postBody.isEmpty else {
            return nil
        }
        if let postBodyTransformBlock = SWHttpTrafficRecorder.shared.postBodyTransformBlock {
            postBody = postBodyTransformBlock(request, postBody)
        }
        return postBody
    }

    private func urlRegexPattern(for request: URLRequest) -> String {
        var urlPattern = request.url?.path ?? ""
        if let query = request.url?.query {
            let queryRegex = try! NSRegularExpression(pattern: "(.*)=(.*)", options: .caseInsensitive)
            let processedQuery = query.components(separatedBy: "&").map { part in
                queryRegex.stringByReplacingMatches(
                    in: part,
                    range: NSRange(location: 0, length: (part as NSString).length),
                    withTemplate: "$1=.*"
                )
            }
            urlPattern = "\(urlPattern)\\?\(processedQuery.joined(separator: "&"))"
        }
        if let urlRegexPatternBlock = SWHttpTrafficRecorder.shared.urlRegexPatternBlock {
            urlPattern = urlRegexPatternBlock(request, urlPattern)
        }
        return urlPattern + "$"
    }
}
