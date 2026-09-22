//
//  RetrieveKYCRequirementsResponseTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 9/22/26.
//

import Foundation
@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp
import XCTest

final class RetrieveKYCRequirementsResponseTests: XCTestCase {

    func testRejectsMissingOrMalformedRequirements() {
        for responseJSON in [
            "{}",
            #"{"requirements": null}"#,
            #"{"requirements": []}"#,
            #"{"requirements": {"entries": []}}"#,
            #"{"requirements": {"source_of_funds": null}}"#,
        ] {
            XCTAssertThrowsError(
                try JSONDecoder().decode(RetrieveKYCRequirementsResponse.self, from: Data(responseJSON.utf8))
            )
        }
    }

    func testPreservesMultipleRequirementNamesRegardlessOfOrder() throws {
        let requirementJSON = #"{"requested_by": "swapped", "awaiting_action_from": "stripe", "errors": []}"#
        for responseJSON in [
            """
            {"requirements": {"proof_of_address": \(requirementJSON), "future_requirement": \(requirementJSON)}}
            """,
            """
            {"requirements": {"future_requirement": \(requirementJSON), "proof_of_address": \(requirementJSON)}}
            """,
        ] {
            let response = try JSONDecoder().decode(RetrieveKYCRequirementsResponse.self, from: Data(responseJSON.utf8))
            XCTAssertEqual(Set(response.requirements.keys), ["proof_of_address", "future_requirement"])
            XCTAssertEqual(response.requirements["proof_of_address"]?.awaitingActionFrom, .stripe)
            XCTAssertEqual(response.requirements["future_requirement"]?.awaitingActionFrom, .stripe)
        }
    }

    func testRejectsMissingOrNullDocumentMetadata() throws {
        let responseData = try RetrieveKYCRequirementsResponseMock.sourceOfFundsWithQuestionnaire.data()
        let responseJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: responseData) as? [String: Any])
        let requirementsJSON = try XCTUnwrap(responseJSON["requirements"] as? [String: Any])
        let requirementJSON = try XCTUnwrap(requirementsJSON["source_of_funds"] as? [String: Any])
        let documentJSON = try XCTUnwrap(requirementJSON["document"] as? [String: Any])

        for field in ["max_file_size_bytes", "min_document_types", "max_document_types", "file_requirements"] {
            for value: Any? in [nil, NSNull()] {
                var invalidDocumentJSON = documentJSON
                invalidDocumentJSON[field] = value
                let invalidDocumentData = try JSONSerialization.data(withJSONObject: invalidDocumentJSON)
                XCTAssertThrowsError(
                    try JSONDecoder().decode(AdditionalKYCDocumentRequirement.self, from: invalidDocumentData),
                    "Expected decoding to fail without a valid \(field)"
                )
            }
        }
    }

    func testRejectsMissingOrNullSubtypeDescription() {
        for subtypeJSON in [
            #"{"id": "payslip", "label": "Payslip"}"#,
            #"{"id": "payslip", "label": "Payslip", "description": null}"#,
        ] {
            XCTAssertThrowsError(
                try JSONDecoder().decode(AdditionalKYCDocumentRequirement.DocumentSubtype.self, from: Data(subtypeJSON.utf8))
            )
        }
    }

    func testDecodesRequirementWithoutQuestionnaire() throws {
        for additionalRequirementsJSON in ["null", "{}", #"{"questionnaire": null}"#] {
            let requirementJSON = """
            {
                "requested_by": "swapped",
                "awaiting_action_from": "partner",
                "errors": [],
                "document": null,
                "additional_requirements": \(additionalRequirementsJSON)
            }
            """
            let requirement = try JSONDecoder().decode(AdditionalKYCRequirement.self, from: Data(requirementJSON.utf8))
            XCTAssertNil(requirement.document)
            XCTAssertNil(requirement.additionalRequirements?.questionnaire)
        }
    }

    func testPreservesQuestionOrderRequiredFlagsAndUnknownAnswerType() throws {
        let requirementJSON = """
        {
            "requested_by": "swapped",
            "awaiting_action_from": "user",
            "errors": [],
            "additional_requirements": {
                "questionnaire": {
                    "questions": [
                        {
                            "id": "purchase_purpose",
                            "prompt": "Why are you purchasing cryptocurrency?",
                            "answer_type": "free_text",
                            "required": true
                        },
                        {
                            "id": "future_question",
                            "prompt": "Additional information",
                            "answer_type": "future_answer_type",
                            "required": false
                        }
                    ]
                }
            }
        }
        """
        let requirement = try JSONDecoder().decode(AdditionalKYCRequirement.self, from: Data(requirementJSON.utf8))
        let questions = try XCTUnwrap(requirement.additionalRequirements?.questionnaire?.questions)
        XCTAssertEqual(questions.map(\.id), ["purchase_purpose", "future_question"])
        XCTAssertEqual(questions.map(\.required), [true, false])
        XCTAssertEqual(questions.map(\.answerType), [.freeText, .unknown("future_answer_type")])
    }
}
