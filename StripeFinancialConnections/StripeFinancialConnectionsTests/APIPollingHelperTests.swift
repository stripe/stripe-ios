//
//  APIPollingHelperTests.swift
//  StripeFinancialConnectionsTests
//
//  Created by Krisjanis Gaidis on 10/2/22.
//

@testable@_spi(STP) import StripeCore
@testable import StripeFinancialConnections
import XCTest

final class APIPollingHelperTests: XCTestCase {

    func testPollingSuccessOnFirstTry() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 0,
            maxNumberOfRetriesClientWillTry: 0
        )

        let expectation = expectation(description: "expect that DataSource 'server' returns a value")
        var result: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                result = apiCallResult
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)

        switch result {
        case .success:
            break  // we expect success
        case .failure:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    func testPollingSuccessAfterFiveTries() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 5,
            maxNumberOfRetriesClientWillTry: 5
        )

        let expectation = expectation(description: "expect that DataSource 'server' returns a value")
        var result: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                result = apiCallResult
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)

        switch result {
        case .success:
            break  // we expect success
        case .failure:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    func testClientPollingMoreThanWhatServerNeeds() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 5,
            // client is able to try more than the "5" required times
            maxNumberOfRetriesClientWillTry: 10
        )

        let expectation = expectation(description: "expect that DataSource 'server' returns a value")
        var result: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                result = apiCallResult
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)

        switch result {
        case .success:
            break  // we expect success
        case .failure:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    func testClientPollingLessThanWhatServerNeeds() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 6,
            maxNumberOfRetriesClientWillTry: 5
        )

        let expectation = expectation(description: "expect that DataSource 'server' returns a value")
        var result: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                result = apiCallResult
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 5)

        switch result {
        case .success:
            XCTFail()
        case .failure:
            break  // we expect failure
        case .none:
            XCTFail()
        }
    }

    func testPollingDefaults() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 2,
            maxNumberOfRetriesClientWillTry: nil  // use default polling
        )

        let expectation = expectation(description: "expect that DataSource 'server' returns a value")
        var result: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                result = apiCallResult
                expectation.fulfill()
            }
        wait(for: [expectation], timeout: 10)  // add extra time-out to make up for defaults

        switch result {
        case .success:
            break  // we expect success
        case .failure:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    func testPollingTwice() throws {
        let dataSource = DataSource(
            numberOfRetriesUntilServerReturnsSuccess: 4,
            maxNumberOfRetriesClientWillTry: 2
        )

        // lets try polling, but it will fail because server needs 4 tries (we only try 2 times)
        let firstPollingExpectation = expectation(description: "expect that DataSource 'server' returns a value")
        var firstPollResult: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                firstPollResult = apiCallResult
                firstPollingExpectation.fulfill()
            }
        wait(for: [firstPollingExpectation], timeout: 5)
        switch firstPollResult {
        case .success:
            XCTFail()
        case .failure:
            break  // we expect failure
        case .none:
            XCTFail()
        }

        // lets try polling again, and it should now succeed
        //
        // we expect client to "reset" the poll try count
        let secondPollingExpectation = expectation(description: "expect that DataSource 'server' returns a value")
        var secondPollResult: Result<TestModel, Error>?
        dataSource.pollAPICall()
            .observe { apiCallResult in
                secondPollResult = apiCallResult
                secondPollingExpectation.fulfill()
            }
        wait(for: [secondPollingExpectation], timeout: 5)
        switch secondPollResult {
        case .success:
            break  // we expect to succeed the second time
        case .failure:
            XCTFail()
        case .none:
            XCTFail()
        }
    }

    func testPollingHelperDeallocAfterPollingFinishes() {
        let apiCallFinishedExpectation = expectation(description: "")
        let apiCall: () -> Future<TestModel> = {
            DispatchQueue.main.async {
                apiCallFinishedExpectation.fulfill()
            }
            return Promise(value: TestModel())
        }

        var apiPollingHelper: APIPollingHelper<TestModel>? = APIPollingHelper(
            apiCall: apiCall,
            pollTimingOptions: APIPollingHelper<TestModel>.PollTimingOptions(
                initialPollDelay: 0.3  // delay to prevent api from calling immediately
            )
        )
        // after this point `apiPollingHelper` should have a strong reference to itself
        apiPollingHelper?.startPollingApiCall()
            .observe { _ in }
        weak var weakAPIPollingHelper = apiPollingHelper
        apiPollingHelper = nil
        XCTAssert(weakAPIPollingHelper != nil)

        // wait for the API call to finish
        wait(for: [apiCallFinishedExpectation], timeout: 1)

        // the `nil` happens after DispatchQueue.main.async, so wait a little bit
        let nilExpectation = expectation(description: "")
        DispatchQueue.main.async {
            nilExpectation.fulfill()
        }
        wait(for: [nilExpectation], timeout: 1)

        // at this point the API should have executed and polling helper should have deallocated itself
        XCTAssert(weakAPIPollingHelper == nil)
    }

    func testInitialDelay() {
        var didCallAPI = false
        let apiCall: () -> Future<TestModel> = {
            didCallAPI = true
            return Promise(value: TestModel())
        }

        let apiPollingHelper = APIPollingHelper(
            apiCall: apiCall,
            pollTimingOptions: APIPollingHelper<TestModel>.PollTimingOptions(
                initialPollDelay: 0.5  // delay to prevent api from calling immediately
            )
        )
        apiPollingHelper.startPollingApiCall()
            .observe { _ in }

        let beforeDelayExpiresExpectation = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            beforeDelayExpiresExpectation.fulfill()
        }
        wait(for: [beforeDelayExpiresExpectation], timeout: 5)

        XCTAssert(!didCallAPI, "API call should be delayed")

        let afterDelayExpiresExpectation = expectation(description: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            afterDelayExpiresExpectation.fulfill()
        }
        wait(for: [afterDelayExpiresExpectation], timeout: 5)

        XCTAssert(didCallAPI, "API call should have been called already")
    }

    func test202ErrorCreation() throws {
        let error = Create202Error()
        if case .apiError(let stripeAPIError) = error {
            XCTAssert(stripeAPIError.statusCode == 202)
        } else {
            XCTFail()
        }
    }
}

private final class DataSource {

    private var numberOfRetriesUntilServerReturnsSuccess: Int
    private let maxNumberOfRetriesClientWillTry: Int?

    init(
        numberOfRetriesUntilServerReturnsSuccess: Int,
        maxNumberOfRetriesClientWillTry: Int?  // null means to use default values
    ) {
        self.numberOfRetriesUntilServerReturnsSuccess = numberOfRetriesUntilServerReturnsSuccess
        self.maxNumberOfRetriesClientWillTry = maxNumberOfRetriesClientWillTry
    }

    func pollAPICall() -> Future<TestModel> {
        let apiCall: () -> Future<TestModel> = { [weak self] in
            guard let self = self else {
                return Promise(
                    error:
                        FinancialConnectionsSheetError
                        .unknown(
                            debugDescription: "DataSource deallocated."
                        )
                )
            }
            return self.serverAPICall()
        }

        let apiPollingHelper = APIPollingHelper(
            apiCall: apiCall,
            pollTimingOptions: {
                if let maxNumberOfRetriesClientWillTry = maxNumberOfRetriesClientWillTry {
                    return APIPollingHelper<TestModel>.PollTimingOptions(
                        initialPollDelay: 0,
                        maxNumberOfRetries: maxNumberOfRetriesClientWillTry,
                        retryInterval: 0
                    )
                } else {
                    // use default Values
                    return APIPollingHelper<TestModel>.PollTimingOptions()
                }
            }()
        )
        return apiPollingHelper.startPollingApiCall()
    }

    // this method pretends to be a "server" that will
    // send a "retry" `numberOfRetriesUntilServerReturnsSuccess`
    // amount of times
    private func serverAPICall() -> Future<TestModel> {
        if numberOfRetriesUntilServerReturnsSuccess > 0 {
            numberOfRetriesUntilServerReturnsSuccess -= 1
            return Promise(error: Create202Error())
        } else {
            return Promise(value: TestModel())
        }
    }
}

private struct TestModel: Codable {}

// "202 response status code indicates that the request has been
//  accepted for processing, but the processing has not been completed"
private func Create202Error() -> StripeError {
    let errorJson: [String: Any] = [
        "error": [
            "type": "api_error"
        ],
    ]
    let errorJsonData = try! JSONSerialization.data(
        withJSONObject: errorJson,
        options: [.prettyPrinted]
    )
    let decodedErrorResponse: StripeAPIErrorResponse = try! StripeJSONDecoder.decode(
        jsonData: errorJsonData
    )
    var apiError = decodedErrorResponse.error!
    apiError.statusCode = 202
    return StripeError.apiError(apiError)
}
