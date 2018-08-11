import XCTest
@testable import UTF8String

extension Swift.String: Error {}

// Testing helper inits
extension _SmallString {
  init?(_ codeUnits: Array<UInt8>) {
    guard let smol = codeUnits.withUnsafeBufferPointer({
      return _SmallString($0)
    }) else {
      return nil
    }
    self = smol
  }
//  init?(_ codeUnits: Array<UInt16>) {
//    guard let smol = codeUnits.withUnsafeBufferPointer({
//      return _SmallString($0)
//    }) else {
//      return nil
//    }
//    self = smol
//  }
}

func expectPrototypeEquivalence(
  _ str: UTF8String.String, _ swiftStr:  Swift.String
) {

  guard str.count == swiftStr.count else { fatalError() }

  let strChars = str.map({ Array($0.unicodeScalars) })
  guard strChars == swiftStr.map({ Array($0.unicodeScalars) })
  else { fatalError() }

  guard str.utf8.elementsEqual(swiftStr.utf8),
        str.utf16.elementsEqual(swiftStr.utf16),
        str.unicodeScalars.elementsEqual(swiftStr.unicodeScalars)
  else { fatalError() }

  // In reverse:

  guard str.reversed().map({ Array($0.unicodeScalars) })
    == swiftStr.reversed().map({ Array($0.unicodeScalars) })
  else { fatalError() }

  // TODO: other views
  guard str.utf8.reversed().elementsEqual(swiftStr.utf8.reversed())
  else { fatalError() }

  guard str.utf16.reversed().elementsEqual(swiftStr.utf16.reversed())
  else { fatalError() }

  guard str.unicodeScalars.reversed().elementsEqual(
    swiftStr.unicodeScalars.reversed()
  ) else { fatalError() }

  expectTrue(true)
}

final class UTF8StringTests: XCTestCase {
  let swiftStr = "the quick 🦊 jumped over the lazy brown 🐶"
  let str = "the quick 🦊 jumped over the lazy brown 🐶" as UTF8String.String

  let cafe = "café" as UTF8String.String
  let cafe2 = "cafe\u{301}" as UTF8String.String
  let swiftCafe = "café"
  let swiftCafe2 = "cafe\u{301}"

  let leadingEmoji = "😀😃😂🙂😘" as UTF8String.String
  let swiftLeadingEmoji = "😀😃😂🙂😘"

  let abc = "abc" as UTF8String.String
  let swiftABC = "abc"
  let def = "def" as UTF8String.String
  let swiftDEF = "def"

  func testExample() {
    // Make sure the types are different
    expectFalse(type(of: swiftStr) == type(of: str))

    let str = UTF8String.String()
    expectTrue(str.isEmpty)

    let hello = "Hello, world!" as UTF8String.String
    print("--- Attemping to greet the world ---")
    print(hello)
    print("--- End attempt ---")

    expectPrototypeEquivalence(hello, "Hello, world!")
  }

  func testUTF8View() {
    expectEqual(swiftStr.utf8.count, str.utf8.count)
    expectEqual(Array(swiftStr.utf8), Array(str.utf8))
    expectEqualSequence(swiftStr.utf8, str.utf8)

    expectEqual(swiftLeadingEmoji.utf8.count, leadingEmoji.utf8.count)
    expectEqual(Array(swiftLeadingEmoji.utf8), Array(leadingEmoji.utf8))
    expectEqualSequence(swiftLeadingEmoji.utf8, leadingEmoji.utf8)
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

    expectEqual(swiftStr.utf16.reversed().count, str.utf16.reversed().count)
    expectEqual(Array(swiftStr.utf16.reversed()), Array(str.utf16.reversed()))
    expectEqualSequence(swiftStr.utf16.reversed(), str.utf16.reversed())

    expectEqual(swiftLeadingEmoji.utf16.count, leadingEmoji.utf16.count)
    expectEqual(Array(swiftLeadingEmoji.utf16), Array(leadingEmoji.utf16))
    expectEqualSequence(swiftLeadingEmoji.utf16, leadingEmoji.utf16)

    expectEqual(swiftLeadingEmoji.utf16.reversed().count, leadingEmoji.utf16.reversed().count)
    expectEqual(Array(swiftLeadingEmoji.utf16.reversed()), Array(leadingEmoji.utf16.reversed()))
    expectEqualSequence(swiftLeadingEmoji.utf16.reversed(), leadingEmoji.utf16.reversed())
  }

  func testCharacterView() {
    expectEqual(swiftStr.count, str.count)
    expectPrototypeEquivalence(str, swiftStr)
  }

  func testBridging() {
    let bridgedSmol = UTF8String.String(_cocoaString: "abc" as NSString)

    expectTrue(bridgedSmol._guts._object.isSmall)

    expectPrototypeEquivalence(bridgedSmol, swiftABC)
    expectEqualSequence(bridgedSmol.utf8, abc.utf8)
    expectEqualSequence(bridgedSmol.utf16, abc.utf16)
    expectEqualSequence(bridgedSmol.unicodeScalars, abc.unicodeScalars)

    expectPrototypeEquivalence(
      UTF8String.String(_cocoaString: bridgedSmol._bridgeToObjectiveCImpl()),
      swiftABC)


    // NOTE: literal intentional for testing purposes...
    let bridgedLarge = UTF8String.String(_cocoaString: "abcdefghijklmnopqrstuvwxyz" as NSString)

    let alphabet = "abcdefghijklmnopqrstuvwxyz"
    expectPrototypeEquivalence(bridgedLarge, alphabet)

    let uniBridged = UTF8String.String(_cocoaString: "café" as NSString)
    expectPrototypeEquivalence(uniBridged, swiftCafe)

    let uniSMPBridged = UTF8String.String(_cocoaString: "abc𓀀🐶🦔défg" as NSString)
    let swiftSMP = "abc𓀀🐶🦔défg"
    expectPrototypeEquivalence(uniSMPBridged, swiftSMP)
  }

  func testComparision() {

    print(cafe)
    print(cafe2)

    expectPrototypeEquivalence(cafe, swiftCafe)
    expectPrototypeEquivalence(cafe2, swiftCafe2)
    expectFalse(cafe.utf8.elementsEqual(cafe2.utf8))
    expectFalse(cafe.unicodeScalars.elementsEqual(cafe2.unicodeScalars))

    expectEqual(swiftCafe, swiftCafe2)
    expectEqual(cafe, cafe2)
  }

  func testHashing() {
    expectFalse(cafe.unicodeScalars.elementsEqual(cafe2.unicodeScalars))
    expectEqual(cafe.hashValue, cafe2.hashValue)

    expectEqual(cafe.map { $0.hashValue }, cafe2.map { $0.hashValue })
  }

  func testSorting() {
    let arr = [def, cafe, str, abc].shuffled().sorted()
    let swiftArr = [
      swiftDEF, swiftCafe, swiftStr, swiftABC
    ].shuffled().sorted()

    for (x, y) in zip(arr, swiftArr) {
      expectPrototypeEquivalence(x, y)
    }

    expectEqualSequence(
      (arr + [cafe2]).shuffled().sorted(),
      [abc, cafe, cafe2, def, str])
    expectEqualSequence(
      (arr + [cafe2]).shuffled().sorted(),
      [abc, cafe2, cafe, def, str])
  }

  func testInterpolation() {
    let smolInterp = "abc\(def)g" as UTF8String.String
    let smolSwiftInterp = "abc\(swiftDEF)g"
    expectPrototypeEquivalence(smolInterp, smolSwiftInterp)


    let interp = "abc\(def)ghijklmnop" as UTF8String.String
    let swiftInterp = "abc\(swiftDEF)ghijklmnop"
    expectPrototypeEquivalence(interp, swiftInterp)

    let uniInterp = "abc\(str)" as UTF8String.String
    let swiftUniInterp = "abc\(swiftStr)"
    expectPrototypeEquivalence(uniInterp, swiftUniInterp)
  }

  func testPrinting() {
    var result = "" as UTF8String.String
    var swiftResult = ""

    UTF8String.print(1, to: &result)
    print(1, to: &swiftResult)

    UTF8String.print(5.25, to: &result)
    print(5.25, to: &swiftResult)

    expectPrototypeEquivalence(result, swiftResult)
  }

  func testCString() {
    let cStr = str.utf8CString
    let swiftCStr = swiftStr.utf8CString
    expectEqual(cStr, swiftCStr)

    str.withCString { ptr in
      // Test for interior pointer
      expectEqual(ptr._asUInt8, str._guts._object.nativeUTF8.baseAddress!)
    }

    // TODO: perf opportunity here...
//    str.dropFirst().withCString { ptr in
//      // Test for interior pointer
//      expectEqual(ptr._asUInt8, 1+str._guts._object.nativeUTF8.baseAddress!)
//    }

    // TODO: others...
  }

  func testStringCreate() {
    let utf8 = UTF8String.String(decoding: str.utf8, as: UTF8.self)
    let utf16 = UTF8String.String(decoding: str.utf16, as: UTF16.self)
    let utf32 = UTF8String.String(
      decoding: str.unicodeScalars.map { $0.value }, as: UTF32.self)

    let swiftUTF8 = Swift.String(decoding: swiftStr.utf8, as: UTF8.self)
    let swiftUTF16 = Swift.String(decoding: swiftStr.utf16, as: UTF16.self)
    let swiftUTF32 = Swift.String(
      decoding: swiftStr.unicodeScalars.map { $0.value }, as: UTF32.self)

    expectPrototypeEquivalence(utf8, swiftUTF8)
    expectPrototypeEquivalence(utf16, swiftUTF16)
    expectPrototypeEquivalence(utf32, swiftUTF32)

    // TODO: others...
  }

  func testSubstring() {
    let subStr = str[...]

    expectPrototypeEquivalence(String(subStr), swiftStr)

    // TODO: other slicing...
  }

  func testJoined() {
    let joined = [str, abc, cafe, def].joined()
    let swiftJoined = [swiftStr, swiftABC, swiftCafe, swiftDEF].joined()

    expectPrototypeEquivalence(joined, swiftJoined)

    let joined2 = [str, abc, def].joined(
      separator: "😀" as UTF8String.String)
    let swiftJoined2 = [swiftStr, swiftABC, swiftDEF].joined(separator: "😀")

    expectPrototypeEquivalence(joined2, swiftJoined2)
  }

  func verifySmallString(_ small: _SmallString, _ input: Swift.String) {
    expectEqual(_SmallString.capacity, small.count + small.unusedCapacity)
    let tiny = Array(input.utf8)
    expectEqual(tiny.count, small.count)
    for (lhs, rhs) in zip(tiny, small) {
      expectEqual(lhs, rhs)
    }

    // Test slicing
    //
    for i in 0..<small.count {
      for j in (i+1)...small.count {
        expectEqualSequence(tiny[i..<j], small[i..<j])
        if j < small.count {
          expectEqualSequence(tiny[i...j], small[i...j])
        }
      }
    }
  }

  func testSmallFitsInSmall() {
    func runTest(_ input: Swift.String) throws {
      let tiny = Array(input.utf8)
      // Constructed from UTF-8 code units
      guard let small = _SmallString(tiny) else {
        throw "Didn't fit"
      }
      verifySmallString(small, input)
    }

    // Pass tests
    //
    expectDoesNotThrow({ try runTest("ab😇c") })
    expectDoesNotThrow({ try runTest("0123456789abcde") })
    expectDoesNotThrow({ try runTest("👨‍👦") })
    expectDoesNotThrow({ try runTest("") })

    // Fail tests
    //
    expectThrows("Didn't fit", { try runTest("0123456789abcdef") })
    expectThrows("Didn't fit", { try runTest("👩‍👦‍👦") })

    for cu in (0 as UInt32)...(0x10FFFF as UInt32) {
      // TODO: Iterate over all scalars when we support UTF-8, and possibly move
      // this to validation suite.
      guard let scalar = Unicode.Scalar(cu) else { continue }
      guard cu <= 0x7F else { break }
      expectDoesNotThrow({ try runTest(String(scalar)) })
    }
  }

  func testSmallAppend() {
    let strings = [
      "",
      "a",
      "bc",
      "def",
      "hijk",
      "lmnop",
      "qrstuv",
      "xyzzzzz",
      "01234567",
      "890123456",
      "7890123456",
      "78901234567",
      "890123456789",
      "0123456789012",
      "34567890123456",
      "789012345678901",
    ]
    let smallstrings = strings.compactMap {
      _SmallString(Array($0.utf8))
    }
    expectEqual(strings.count, smallstrings.count)
    for (small, str) in zip(smallstrings, strings) {
      verifySmallString(small, str)
    }

    for i in 0..<smallstrings.count {
      for j in i..<smallstrings.count {
        let lhs = smallstrings[i]
        let rhs = smallstrings[j]
        if lhs.count + rhs.count > _SmallString.capacity {
          continue
        }
        verifySmallString(
          _SmallString(base: _StringGuts(lhs), appending: _StringGuts(rhs))!,
          strings[i] + strings[j])
        verifySmallString(
          _SmallString(base: _StringGuts(rhs), appending: _StringGuts(lhs))!,
          strings[j] + strings[i])
      }
    }
  }

  func testAppending() {
    func hex(_ x: UInt64) -> UTF8String.String { return String(x, radix:16) }

    func hexAddrVal<T>(_ x: T) -> UTF8String.String {
      return "@0x" + hex(UInt64(unsafeBitCast(x, to: UInt.self)))
    }

    func repr(ns x: NSString) -> UTF8String.String {
      return "\(NSStringFromClass(object_getClass(x)!))\(hexAddrVal(x)) = \"\(x)\""
    }

    func repr(rep x: UTF8String._StringRepresentation) -> UTF8String.String {
      switch x._form {
      case ._small:
        return """
        Small(count: \(x._count))
        """
      case ._cocoa(let object):
        return """
        Cocoa(\
        owner: \(hexAddrVal(object)), \
        count: \(x._count))
        """
      case ._native(let object):
        return """
        Native(\
        owner: \(hexAddrVal(object)), \
        count: \(x._count), \
        capacity: \(x._capacity))
        """
      case ._immortal(_):
        return """
        Unmanaged(count: \(x._count))
        """
      }
    }

    func repr(_ x: UTF8String.String) -> UTF8String.String {
      return "String(\(repr(rep: x._classify()))) = \"\(x)\""
    }
  }

  func testViewCounts() {


    for s in simpleStrings {
      validateViewCount(s, for: s)
      validateViewCount(s.utf8, for: s)
      validateViewCount(s.utf16, for: s)
      validateViewCount(s.unicodeScalars, for: s)

      validateViewCount(s[...], for: s)
      validateViewCount(s[...].utf8, for: s)
      validateViewCount(s[...].utf16, for: s)
      validateViewCount(s[...].unicodeScalars, for: s)
    }
  }

//  static var allTests = [
//    ("testExample", testExample),
//    ]
}

enum SimpleString: UTF8String.String {
  case smallASCII = "abcdefg"
  case smallUnicode = "abéÏ𓀀"
  case largeASCII = "012345678901234567890"
  case largeUnicode = "abéÏ012345678901234567890𓀀"
  case emoji = "😀😃🤢🤮👩🏿‍🎤🧛🏻‍♂️🧛🏻‍♂️👩‍👩‍👦‍👦"
}

let simpleStrings: [UTF8String.String] = [
  SimpleString.smallASCII.rawValue,
  SimpleString.smallUnicode.rawValue,
  SimpleString.largeASCII.rawValue,
  SimpleString.largeUnicode.rawValue,
  SimpleString.emoji.rawValue,
]


func validateViewCount<View: BidirectionalCollection>(
  _ view: View, for string: UTF8String.String,
//  stackTrace: SourceLocStack = SourceLocStack(),
//  showFrame: Bool = true,
  file: UTF8String.String = #file, line: UInt = #line
  ) where View.Element: Equatable, View.Index == UTF8String.String.Index {

//  var stackTrace = stackTrace.pushIf(showFrame, file: file, line: line)

  let count = view.count
  func expect(_ i: Int,
              file: UTF8String.String = #file, line: UInt = #line
    ) {
    expectEqual(count, i//, "for String: \(string)",
//      stackTrace: stackTrace.pushIf(showFrame, file: file, line: line),
//      showFrame: false)
    )
  }

  let reversedView = view.reversed()

  expect(Array(view).count)
  expect(view.indices.count)
  expect(view.indices.reversed().count)
  expect(reversedView.indices.count)
  expect(view.distance(from: view.startIndex, to: view.endIndex))
  expect(reversedView.distance(
    from: reversedView.startIndex, to: reversedView.endIndex))

  // Access the elements from the indices
  expectEqual(Array(view), view.indices.map { view[$0] })
  expectEqual(
    Array(reversedView), reversedView.indices.map { reversedView[$0] })

  let indicesArray = Array<UTF8String.String.Index>(view.indices)
  for i in 0..<indicesArray.count {
    var idx = view.startIndex
    idx = view.index(idx, offsetBy: i)
    expectEqual(indicesArray[i], idx)
  }
}
