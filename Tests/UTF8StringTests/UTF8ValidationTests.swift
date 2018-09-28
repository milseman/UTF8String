import XCTest
@testable import UTF8String

public class UTF8ValidationTest: XCTestCase {
    struct TestError: Error {
        let result: UTF8ValidationResult
    }

    func run(_ bytes: UnsafeBufferPointer<UInt8>) throws {
        if case .error(let range) = _betterValidateUTF8(bytes) {
            throw TestError(result: .error(toBeReplaced: range))
        }
    }

    func assertValidUTF8(_ bytes: UnsafeBufferPointer<UInt8>, _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) {
        do {
            return try self.run(bytes)
        } catch {
            XCTFail("not valid: \(error)", file: file, line: line)
        }
    }

    func assertInvalidUTF8(_ bytes: UnsafeBufferPointer<UInt8>,
                           expectedErrorRange: Range<Int>,
                           expectedRepairedString: UTF8String.String,
                           _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) {
        func errorFormat(_ value: (Swift.String, UTF8ValidationResult?)) -> (Swift.String, Swift.String) {
            return (value.0, value.1.map(String.init(describing:)) ?? "<no error>")
        }
        do {
            try self.run(bytes)
            XCTFail("\(message) is valid", file: file, line: line)
        } catch let e as TestError {
            XCTAssertEqual(UTF8ValidationResult.error(toBeReplaced: expectedErrorRange), e.result, message, file: file, line: line)
            let repaired = utf8Repair(bytes, firstKnownBrokenRange: expectedErrorRange)
            XCTAssertEqual(expectedRepairedString, repaired, "repaired string wrong", file: file, line: line)
        } catch {
            fatalError("unexpected error \(error)")
        }
    }

    func assertValidUTF8(_ bytes: [UInt8], _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) {
        bytes.withUnsafeBufferPointer { ptr in
            self.assertValidUTF8(ptr, message, file: file, line: line)
        }
    }

    func assertInvalidUTF8(_ bytes: [UInt8], expectedErrorRange: Range<Int>, expectedRepairedString: UTF8String.String, _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) {
        bytes.withUnsafeBufferPointer { ptr in
            self.assertInvalidUTF8(ptr, expectedErrorRange: expectedErrorRange, expectedRepairedString: expectedRepairedString, message, file: file, line: line)
        }
    }

    func assertValidUTF8<Bytes: Collection>(_ bytes: Bytes, _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) where Bytes.Element == UInt8 {
        self.assertValidUTF8(Array(bytes), message, file: file, line: line)
    }

    func assertInvalidUTF8<Bytes: Collection>(_ bytes: Bytes, expectedErrorRange: Range<Int>, expectedRepairedString: UTF8String.String, _ message: Swift.String = "", file: StaticString = #file, line: UInt = #line) where Bytes.Element == UInt8 {
        self.assertInvalidUTF8(Array(bytes), expectedErrorRange: expectedErrorRange, expectedRepairedString: expectedRepairedString, message, file: file, line: line)
    }

    // MARK: Utils
    func makeUTF8ContinuationSequence(totalNumberBytes: Int) -> [UInt8] {
        precondition(totalNumberBytes > 0)
        guard totalNumberBytes > 1 else {
            return [0]
        }
        var firstByte: UInt8 = 0
        for i in 0..<8 {
            firstByte |= firstByte | (i <= totalNumberBytes ? 1 : 0)
            firstByte <<= 1
        }
        return [firstByte]+repeatElement(0b1000_0000, count: totalNumberBytes-1)
    }

    private let replacementChar: UTF8String.String = String(decoding: utf8ReplacementCharacter, as: UTF8.self)

    // MARK: Tests
    func testValid_Empty() {
        self.assertValidUTF8([])
    }

    func testValid_OneCharacterASCII() {
        self.assertValidUTF8(" ".utf8)
    }

    func testInvalid_ContinuationEndByteWithoutContinuation() {
        self.assertInvalidUTF8([0b1000_0000], expectedErrorRange: 0..<1, expectedRepairedString: self.replacementChar)
    }

    func testInvalid_ContinuationStartByteOnly() {
        self.assertInvalidUTF8([0b1100_0000], expectedErrorRange: 0..<1, expectedRepairedString: self.replacementChar)
        self.assertInvalidUTF8([0b1110_0000], expectedErrorRange: 0..<1, expectedRepairedString: self.replacementChar)
        self.assertInvalidUTF8([0b1111_0000], expectedErrorRange: 0..<1, expectedRepairedString: self.replacementChar)
    }

    func testInvalid_OnlyTheRawContinuationBytesNoActualData() {
        for i in 2...4 {
            let bytes = makeUTF8ContinuationSequence(totalNumberBytes: i)
            self.assertInvalidUTF8(bytes,
                                   expectedErrorRange: 0..<i,
                                   expectedRepairedString: self.replacementChar,
                                   "\(bytes) (\(i) bytes)")
        }
    }

    func testValid_SomeContinuations() {
        for i in 2...4 {
            let bytes = makeUTF8ContinuationSequence(totalNumberBytes: i).map { $0 | 0b10 /* make them valid */ }
            self.assertValidUTF8(bytes, "\(bytes) (\(i) bytes)")
        }
    }

    func testInvalid_ContinuationsMissingBytes() {
        for i in 2...4 {
            for dropLast in 1..<i {
            let bytes = makeUTF8ContinuationSequence(totalNumberBytes: i)
                .map { $0 | 0b10 /* make them valid */ }
                .dropLast(dropLast) /* and invalid again */
                self.assertInvalidUTF8(bytes,
                                       expectedErrorRange: 0..<(i-dropLast),
                                       expectedRepairedString: self.replacementChar,
                                       "\(bytes) (\(i) bytes), i=\(i), dropLast=\(dropLast)")
            }
        }
    }

    func testValid_MultipleValidsConcatenated() {
        let allBytes: [UInt8] = (1...4).flatMap { i in
            return makeUTF8ContinuationSequence(totalNumberBytes: i).map { $0 | 0b10 /* make them valid */ }
        }
        self.assertValidUTF8(allBytes, "\(allBytes)")
    }

    func testInvalid_MultipleValidsInterspersedWithInvalids() {
        let illegalSequences: [[UInt8]] = [[0xC0], [0xC1], Array(0xF5...0xFF)]
        let validBytes: [UInt8] = (1...4).flatMap { i in
            return makeUTF8ContinuationSequence(totalNumberBytes: i).map { $0 | 0b10 /* make them valid */ }
        }
        self.assertValidUTF8(validBytes, "\(validBytes)")

        for illegalSequence in illegalSequences {
            for illegalStarterIndex in [0, 1, 3, 6, 10] {
                var invalidBytes = validBytes
                var expectedRepairedBytes = validBytes
                invalidBytes.insert(contentsOf: illegalSequence, at: illegalStarterIndex)
                expectedRepairedBytes.insert(contentsOf: utf8ReplacementCharacter, at: illegalStarterIndex)
                self.assertInvalidUTF8(invalidBytes,
                                       expectedErrorRange: illegalStarterIndex..<(illegalStarterIndex + illegalSequence.count),
                                       expectedRepairedString: UTF8String.String(decoding: expectedRepairedBytes, as: UTF8.self),
                                       "\(invalidBytes); illegalSequence=\(illegalSequence), illegalStarterIndex=\(illegalStarterIndex)")
            }
        }
    }

    func testValid_replacementChracterIsValid() {
        let bytes: [UInt8] = [0xEF, 0xBF, 0xBD]
        self.assertValidUTF8(bytes, "\(bytes)")
    }

    func testInvalid_longSequenceOfTruncatedBytes() {
        let truncatedSequence = makeUTF8ContinuationSequence(totalNumberBytes: 4).first!
        let longSequence: [UInt8] = Array(repeating: truncatedSequence, count: 1000)
        let expectedOutput = UTF8String.String(decoding: (0..<1000).flatMap { _ in utf8ReplacementCharacter }, as: UTF8.self)
        longSequence.withUnsafeBufferPointer { ptr in
            let firstBrokenSequence = 0..<1
            self.assertInvalidUTF8(ptr,
                                   expectedErrorRange: 0..<1,
                                   expectedRepairedString: expectedOutput)
            let string = utf8Repair(ptr, firstKnownBrokenRange: firstBrokenSequence)
            XCTAssertEqual(expectedOutput, string)
        }
    }

    func testInvalid_asciiLeftOfSomethingBroken() {
        let brokenBytes = ["a".utf8.first!, "🔥".utf8.first!]
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 1..<2,
                               expectedRepairedString: "a" + self.replacementChar)
    }

    func testInvalid_asciiRightOfSomethingBroken() {
        let brokenBytes = ["🔥".utf8.first!, "a".utf8.first!]
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 0..<1,
                               expectedRepairedString: self.replacementChar + "a")
    }

    func testInvalid_somethingBrokenSandwichedInASCII() {
        let brokenBytes = ["A".utf8.first!, "🔥".utf8.first!, "Z".utf8.first!]
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 1..<2,
                               expectedRepairedString: "A" + self.replacementChar + "Z")
    }

    func causesCrash_testInvalid_flagLeftOfSomethingBroken() {
        let brokenBytes = Array("🏴󠁧󠁢󠁳󠁣󠁴󠁿".utf8) + ["🔥".utf8.first!]
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 28..<29,
                               expectedRepairedString: "🏴󠁧󠁢󠁳󠁣󠁴󠁿" + self.replacementChar)
    }

    func testInvalid_flagRightOfSomethingBroken() {
        let brokenBytes = Array("🤞".utf8.dropLast()) + Array("🏴󠁧󠁢󠁳󠁣󠁴󠁿".utf8)
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 0..<3,
                               expectedRepairedString: self.replacementChar + "🏴󠁧󠁢󠁳󠁣󠁴󠁿")
    }

    func causesCrash_testInvalid_somethingBrokenSandwichedInFlags() {
        let brokenBytes = Array("🏴󠁧󠁢󠁳󠁣󠁴󠁿".utf8) + ["🔥".utf8.first!] + Array("🏴󠁧󠁢󠁳󠁣󠁴󠁿".utf8)
        self.assertInvalidUTF8(brokenBytes,
                               expectedErrorRange: 28..<29,
                               expectedRepairedString: "🏴󠁧󠁢󠁳󠁣󠁴󠁿" + self.replacementChar + "🏴󠁧󠁢󠁳󠁣󠁴󠁿")
    }

}
