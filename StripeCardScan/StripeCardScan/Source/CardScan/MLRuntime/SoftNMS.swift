//
//  SoftNMS.swift
//  CardScan
//
//  Created by xaen on 4/3/20.
//

import Accelerate
import Foundation

struct SoftNMS {
    static func softNMS(
        subsetBoxes: [[Float]],
        probs: [Float],
        probThreshold: Float,
        sigma: Float,
        topK: Int,
        candidateSize: Int
    ) -> ([[Float]], [Float]) {

        var pickedBoxes = [[Float]]()
        var pickedScores = [Float]()

        var subsetBoxes = subsetBoxes
        var probs = probs

        while subsetBoxes.count > 0 {
            var maxElement: Float = 0.0
            var vdspIndex: vDSP_Length = 0
            vDSP_maxvi(probs, 1, &maxElement, &vdspIndex, vDSP_Length(probs.count))
            let maxIdx = Int(vdspIndex)

            let currentBox = subsetBoxes[maxIdx]
            pickedBoxes.append(subsetBoxes[maxIdx])
            pickedScores.append(maxElement)

            if subsetBoxes.count == 1 {
                break
            }

            // Take the last box and replace the max box with the last box
            subsetBoxes.remove(at: maxIdx)
            probs.remove(at: maxIdx)

            var ious = [Float](repeating: 0.0, count: subsetBoxes.count)
            let currentBoxRect = CGRect(
                x: Double(currentBox[0]),
                y: Double(currentBox[1]),
                width: Double(currentBox[2] - currentBox[0]),
                height: Double(currentBox[3] - currentBox[1])
            )

            for i in 0..<subsetBoxes.count {
                ious[i] = currentBoxRect.iou(
                    nextBox: CGRect(
                        x: Double(subsetBoxes[i][0]),
                        y: Double(subsetBoxes[i][1]),
                        width: Double(subsetBoxes[i][2] - subsetBoxes[i][0]),
                        height: Double(subsetBoxes[i][3] - subsetBoxes[i][1])
                    )
                )
            }

            var probsPrunned = [Float]()
            var subsetBoxesPrunned = [[Float]]()
            for i in 0..<probs.count {
                probs[i] = probs[i] * exp(-(ious[i] * ious[i]) / sigma)
                if probs[i] > probThreshold {
                    probsPrunned.append(probs[i])
                    subsetBoxesPrunned.append(subsetBoxes[i])
                }
            }
            probs = probsPrunned
            subsetBoxes = subsetBoxesPrunned
        }

        return (pickedBoxes, pickedScores)
    }

}
