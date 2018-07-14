import XCTest
@testable import UTF8String

func compareEqual(_ str: UTF8String.String, _ swiftStr:  Swift.String) -> Bool {
  return str.map { Array($0.unicodeScalars) }
    == swiftStr.map { Array($0.unicodeScalars) }
}

final class UTF8StringTests: XCTestCase {
  let swiftStr = "the quick 🦊 jumped over the lazy brown 🐶"
  let str = "the quick 🦊 jumped over the lazy brown 🐶" as UTF8String.String

  func testExample() {
    // Make sure the types are different
    expectFalse(type(of: swiftStr) == type(of: str))

    let str = UTF8String.String()
    expectTrue(str.isEmpty)

    let hello = "Hello, world!" as UTF8String.String
    print("--- Attemping to greet the world ---")
    print(hello)
    print("--- End attempt ---")
  }

  func testUTF8View() {
    expectEqual(swiftStr.utf8.count, str.utf8.count)
    expectEqual(Array(swiftStr.utf8), Array(str.utf8))
    expectEqualSequence(swiftStr.utf8, str.utf8)
  }

  func testUnicodeScalarView() {
    expectEqual(swiftStr.unicodeScalars.count, str.unicodeScalars.count)
    expectEqual(Array(swiftStr.unicodeScalars), Array(str.unicodeScalars))
    expectEqualSequence(swiftStr.unicodeScalars, str.unicodeScalars)
  }

  func testUTF16View() {
    expectEqual(swiftStr.utf16.count, str.utf16.count)
    expectEqual(Array(swiftStr.utf16), Array(str.utf16))
    expectEqualSequence(swiftStr.utf16, str.utf16)
  }

  func testCharacterView() {
    expectEqual(swiftStr.count, str.count)
    expectTrue(compareEqual(str, swiftStr))
  }

  func testBridging() {
    let bridgedSmol = UTF8String.String(_cocoaString: "abc" as NSString)

    expectTrue(bridgedSmol._guts._object.isSmall)

    expectTrue(compareEqual(bridgedSmol, "abc"))

    let bridgedLarge = UTF8String.String(_cocoaString: """
      abcdefghijklmnopqrstuvwxyz
      """ as NSString)
    print(bridgedLarge)
    expectTrue(compareEqual(bridgedLarge, "abcdefghijklmnopqrstuvwxyz"))
  }

//  static var allTests = [
//    ("testExample", testExample),
//    ]
}
