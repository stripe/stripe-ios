import Foundation

/// Organize the boxes to find possible numbers.
///
/// After running detection, the post processing algorithm will try to find
/// sequences of boxes that are plausible card numbers. The basic techniques
/// that it uses are non-maximum suppression and depth first search on box
/// sequences to find likely numbers. There are also a number of heuristics
/// for filtering out unlikely sequences.
struct PostDetectionAlgorithm {
    let kNumberWordCount = 4
    let kAmexWordCount = 5
    let kMaxBoxesToDetect = 20
    let kDeltaRowForCombine = 2
    let kDeltaColForCombine = 2
    let kDeltaRowForHorizontalNumbers = 1
    let kDeltaColForVerticalNumbers = 1

    let sortedBoxes: [DetectedBox]
    let numRows: Int
    let numCols: Int

    init(
        boxes: [DetectedBox]
    ) {
        self.sortedBoxes = boxes.sorted { $0.confidence > $1.confidence }.prefix(kMaxBoxesToDetect)
            .map { $0 }

        // it's ok if this doesn't match the card row/col counts because we only
        // use this for our internal algorithms. I prefer doing this as it make
        // proving array bounds easier since everything is local and as long as
        // we only access arrays using row/col from our boxes then we'll always
        // be in bounds
        self.numRows = (self.sortedBoxes.map { $0.row }.max() ?? 0) + 1
        self.numCols = (self.sortedBoxes.map { $0.col }.max() ?? 0) + 1
    }

    /// Finds traditional numbers that are horizontal on a 16 digit card.
    func horizontalNumbers() -> [[DetectedBox]] {
        let boxes = self.combineCloseBoxes(
            deltaRow: kDeltaRowForCombine,
            deltaCol: kDeltaColForCombine
        )
        let lines = self.findHorizontalNumbers(words: boxes, numberOfBoxes: kNumberWordCount)

        // boxes should be roughly evenly spaced, reject any that aren't
        return lines.filter { line in
            let deltas = zip(line, line.dropFirst()).map { box, nextBox in nextBox.col - box.col }
            let maxDelta = deltas.max() ?? 0
            let minDelta = deltas.min() ?? 0

            return (maxDelta - minDelta) <= 2
        }
    }

    /// Used for Visa quick read where the digits are in groups of four but organized veritcally
    func verticalNumbers() -> [[DetectedBox]] {
        let boxes = self.combineCloseBoxes(
            deltaRow: kDeltaRowForCombine,
            deltaCol: kDeltaColForCombine
        )
        let lines = self.findVerticalNumbers(words: boxes, numberOfBoxes: kNumberWordCount)

        // boxes should be roughly evenly spaced, reject any that aren't
        return lines.filter { line in
            let deltas = zip(line, line.dropFirst()).map { box, nextBox in nextBox.row - box.row }
            let maxDelta = deltas.max() ?? 0
            let minDelta = deltas.min() ?? 0

            return (maxDelta - minDelta) <= 2
        }
    }

    /// Finds 15 digit horizontal Amex card numbers.
    ///
    /// Amex has groups of 4 6 5 numbers and our detection algorithm detects clusters of four
    /// digits, but we did design it to detect the groups of four within the clusters of 5 and 6.
    /// Thus, our goal with Amex is to find enough boxes of 4 to cover all of the amex digits.
    func amexNumbers() -> [[DetectedBox]] {
        let boxes = self.combineCloseBoxes(deltaRow: kDeltaRowForCombine, deltaCol: 1)
        let lines = self.findHorizontalNumbers(words: boxes, numberOfBoxes: kAmexWordCount)

        return lines.filter { line in
            let colDeltas = zip(line, line.dropFirst()).map { box, nextBox in nextBox.col - box.col
            }

            // we have roughly evenly spaced clusters. A single box of four, a cluster of 6 and then
            // a cluster of 5. We try to recognize the first and last few digits of the 5 and 6
            // cluster, and the 5 and 6 cluster are roughly evenly spaced but the boxes within
            // are close
            let evenColDeltas = colDeltas.enumerated().filter { $0.0 % 2 == 0 }.map { $0.1 }
            let oddColDeltas = colDeltas.enumerated().filter { $0.0 % 2 == 1 }.map { $0.1 }
            let evenOddDeltas = zip(evenColDeltas, oddColDeltas).map { even, odd in
                Double(even) / Double(odd)
            }

            return evenOddDeltas.reduce(true) { $0 && $1 >= 2.0 }
        }
    }

    /// Combine close boxes favoring high confidence boxes.
    func combineCloseBoxes(deltaRow: Int, deltaCol: Int) -> [DetectedBox] {
        var cardGrid: [[Bool]] = Array(
            repeating: Array(repeating: false, count: self.numCols),
            count: self.numRows
        )

        for box in self.sortedBoxes {
            cardGrid[box.row][box.col] = true
        }

        // since the boxes are sorted by confidence, go through them in order to
        // result in only high confidence boxes winning. There are corner cases
        // where this will leave extra boxes, but that's ok because we don't
        // need to be perfect here
        for box in self.sortedBoxes {
            if cardGrid[box.row][box.col] == false {
                continue
            }
            for row in (box.row - deltaRow)...(box.row + deltaRow) {
                for col in (box.col - deltaCol)...(box.col + deltaCol) {
                    if row >= 0 && row < numRows && col >= 0 && col < numCols {
                        cardGrid[row][col] = false
                    }
                }
            }
            // add this box back
            cardGrid[box.row][box.col] = true
        }

        return self.sortedBoxes.filter { cardGrid[$0.row][$0.col] }
    }

    /// Find all boxes that form a sequence of four boxes.
    ///
    /// Does a depth first search on all boxes to find all boxes that form
    /// a line with four boxes. The predicate dictates which boxes are added
    /// so we have a separate prediate for horizontal vs vertical numbers.
    func findNumbers(
        currentLine: [DetectedBox],
        words: [DetectedBox],
        predicate: ((DetectedBox, DetectedBox) -> Bool),
        numberOfBoxes: Int,
        lines: inout [[DetectedBox]]
    ) {

        if currentLine.count == numberOfBoxes {
            lines.append(currentLine)
            return
        }

        if words.count == 0 {
            return
        }

        guard let currentWord = currentLine.last else {
            return
        }

        for (idx, word) in words.enumerated() {
            if predicate(currentWord, word) {
                findNumbers(
                    currentLine: (currentLine + [word]),
                    words: words.dropFirst(idx + 1).map { $0 },
                    predicate: predicate,
                    numberOfBoxes: numberOfBoxes,
                    lines: &lines
                )
            }
        }
    }

    func verticalAddBoxPredicate(_ currentWord: DetectedBox, _ nextWord: DetectedBox) -> Bool {
        let deltaCol = kDeltaColForVerticalNumbers
        return nextWord.row > currentWord.row && nextWord.col >= (currentWord.col - deltaCol)
            && nextWord.col <= (currentWord.col + deltaCol)
    }

    func horizontalAddBoxPredicate(_ currentWord: DetectedBox, _ nextWord: DetectedBox) -> Bool {
        let deltaRow = kDeltaRowForHorizontalNumbers
        return nextWord.col > currentWord.col && nextWord.row >= (currentWord.row - deltaRow)
            && nextWord.row <= (currentWord.row + deltaRow)
    }

    // Note: this is simple but inefficient. Since we're dealing with small
    // lists (eg 20 items) it should be fine
    func findHorizontalNumbers(words: [DetectedBox], numberOfBoxes: Int) -> [[DetectedBox]] {
        let sortedWords = words.sorted { $0.col < $1.col }
        var lines: [[DetectedBox]] = [[]]

        for (idx, word) in sortedWords.enumerated() {
            findNumbers(
                currentLine: [word],
                words: sortedWords.dropFirst(idx + 1).map { $0 },
                predicate: horizontalAddBoxPredicate,
                numberOfBoxes: numberOfBoxes,
                lines: &lines
            )
        }

        return lines
    }

    func findVerticalNumbers(words: [DetectedBox], numberOfBoxes: Int) -> [[DetectedBox]] {
        let sortedWords = words.sorted { $0.row < $1.row }
        var lines: [[DetectedBox]] = [[]]

        for (idx, word) in sortedWords.enumerated() {
            findNumbers(
                currentLine: [word],
                words: sortedWords.dropFirst(idx + 1).map { $0 },
                predicate: verticalAddBoxPredicate,
                numberOfBoxes: numberOfBoxes,
                lines: &lines
            )
        }

        return lines
    }

}
