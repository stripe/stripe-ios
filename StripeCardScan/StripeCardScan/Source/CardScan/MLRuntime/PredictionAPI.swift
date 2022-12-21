//
//  PredictionAPI.swift
//  CardScan
//
//  Created by Zain on 8/6/19.
//

import Foundation

struct Result {
    var pickedBoxProbs: [Float]
    var pickedLabels: [Int]
    var pickedBoxes: [[Float]]

    init() {
        pickedBoxProbs = [Float]()
        pickedLabels = [Int]()
        pickedBoxes = [[Float]]()
    }
}
struct PredictionAPI {

    /// * A utitliy struct that applies non-max supression to each class
    /// * picks out the remaining boxes, the class probabilities for classes
    /// * that are kept and composes all the information in one place to be returned as
    /// * an object.
    func predictionAPI(
        scores: [[Float]],
        boxes: [[Float]],
        probThreshold: Float,
        iouThreshold: Float,
        candidateSize: Int,
        topK: Int
    ) -> Result {
        var pickedBoxes: [[Float]] = [[Float]]()
        var pickedLabels: [Int] = [Int]()
        var pickedBoxProbs: [Float] = [Float]()

        for classIndex in 1..<scores[0].count {
            var probs: [Float] = [Float]()
            var subsetBoxes: [[Float]] = [[Float]]()
            var indicies: [Int] = [Int]()

            for rowIndex in 0..<scores.count {
                if scores[rowIndex][classIndex] > probThreshold {
                    probs.append(scores[rowIndex][classIndex])
                    subsetBoxes.append(boxes[rowIndex])
                }
            }

            if probs.count == 0 {
                continue
            }

            indicies = NMS.hardNMS(
                subsetBoxes: subsetBoxes,
                probs: probs,
                iouThreshold: iouThreshold,
                topK: topK,
                candidateSize: candidateSize
            )

            for idx in indicies {
                pickedBoxProbs.append(probs[idx])
                pickedBoxes.append(subsetBoxes[idx])
                pickedLabels.append(classIndex)
            }
        }
        var result: Result = Result()
        result.pickedBoxProbs = pickedBoxProbs
        result.pickedLabels = pickedLabels
        result.pickedBoxes = pickedBoxes

        return result

    }

}
