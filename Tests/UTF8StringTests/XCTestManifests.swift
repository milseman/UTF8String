import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(UTF8StringTests.allTests),
    testCase(UTF8ValidationTests.allTests),
  ]
}
#endif
