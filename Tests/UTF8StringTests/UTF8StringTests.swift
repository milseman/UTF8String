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

  let leadingEmoji = "😀" as UTF8String.String// 😃😂🙂😘" as UTF8String.String
  let swiftLeadingEmoji = "😀" // 😃😂🙂😘"

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

    str.withCString { ptr in
      expectPrototypeEquivalence(str, Swift.String(cString: ptr))
      expectPrototypeEquivalence(UTF8String.String(cString: ptr), swiftStr)
    }

    let subStr = str.dropFirst()
    let swiftSubStr = swiftStr.dropFirst()
    subStr.withCString { ptr in
      expectPrototypeEquivalence(
        UTF8String.String(subStr), Swift.String(cString: ptr))
      expectPrototypeEquivalence(
        UTF8String.String(cString: ptr), Swift.String(swiftSubStr))
    }

    str.withCString(encodedAs: UTF32.self) { ptr in
      expectPrototypeEquivalence(str, Swift.String(decodingCString: ptr, as: UTF32.self))
      expectPrototypeEquivalence(UTF8String.String(decodingCString: ptr, as: UTF32.self), swiftStr)
    }
    subStr.withCString(encodedAs: UTF32.self) { ptr in
      expectPrototypeEquivalence(
        UTF8String.String(subStr), Swift.String(decodingCString: ptr, as: UTF32.self))
      expectPrototypeEquivalence(
        UTF8String.String(decodingCString: ptr, as: UTF32.self), Swift.String(swiftSubStr))
    }
  }

  func testInsert() {
    var localStr = str
    var localSwiftStr = swiftStr
    for _ in 0..<100 {
      localStr.insert(("朝" as UTF8String.Character), at: localStr.startIndex)
      localSwiftStr.insert("朝", at: localSwiftStr.startIndex)
      localStr.insert(("朝" as UTF8String.Character), at: localStr.endIndex)
      localSwiftStr.insert("朝", at: localSwiftStr.endIndex)
    }
    expectPrototypeEquivalence(localStr, localSwiftStr)
  }

  func testNSStringInit() {
    expectEqual("foo, a basmati bar!",
                        String(cString:
                          "foo, a basmati bar!", encoding: String.defaultCStringEncoding)!)
    expectEqual("foo, a basmati bar!",
                        UTF8String.String(cString:
                          "foo, a basmati bar!", encoding: String.defaultCStringEncoding)!)
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


  func testSubScalarSlicing() {
    struct NSRange { var location, length: Int }

    func NSFakeRange(_ location: Int, _ length: Int) -> NSRange {
      return NSRange(location: location, length: length)
    }

    func substring(of _storage: UTF8String.String, with range: NSRange) -> UTF8String.String {
      let start = _storage.utf16.startIndex
      let min = _storage.utf16.index(start, offsetBy: range.location)
      let max = _storage.utf16.index(
        start, offsetBy: range.location + range.length)

      if let substr = UTF8String.String(_storage.utf16[min..<max]) {
        return substr
      }
      //If we come here, then the range has created unpaired surrogates on either end.
      //An unpaired surrogate is replaced by OXFFFD - the Unicode Replacement Character.
      //The CRLF ("\r\n") sequence is also treated like a surrogate pair, but its constinuent
      //characters "\r" and "\n" can exist outside the pair!

      let replacementCharacter = UTF8String.String(describing: UnicodeScalar(0xFFFD)!)
      let CR: UInt16 = 13  //carriage return
      let LF: UInt16 = 10  //new line

      //make sure the range is of non-zero length
      guard range.length > 0 else { return "" as UTF8String.String }

      //if the range is pointing to a single unpaired surrogate
      if range.length == 1 {
        switch _storage.utf16[min] {
        case CR: return "\r"
        case LF: return "\n"
        default: return replacementCharacter
        }
      }

      //set the prefix and suffix characters
      let prefix = _storage.utf16[min] == LF ? "\n" : replacementCharacter
      let suffix = _storage.utf16[_storage.utf16.index(before: max)] == CR
        ? "\r" : replacementCharacter

      let postMin = _storage.utf16.index(after: min)

      //if the range breaks a surrogate pair at the beginning of the string
      if let substrSuffix = String(
        _storage.utf16[postMin..<max]) {
        return prefix + substrSuffix
      }

      let preMax = _storage.utf16.index(before: max)
      //if the range breaks a surrogate pair at the end of the string
      if let substrPrefix = String(_storage.utf16[min..<preMax]) {
        return substrPrefix + suffix
      }

      //the range probably breaks surrogate pairs at both the ends
      guard postMin <= preMax else { return prefix + suffix }

      let substr =  String(_storage.utf16[postMin..<preMax])!
      return prefix + substr + suffix
    }

    // let trivial = "swift.org"
    // expectEqual(substring(of: trivial, with: NSFakeRange(0, 5)), "swift")

    let surrogatePairSuffix = "Hurray🎉" as UTF8String.String
    expectEqual(substring(of: surrogatePairSuffix, with: NSFakeRange(0, 7)), "Hurray�" as UTF8String.String)
  }

  func testViewIndexMapping() {

    let replacementUTF16: UTF16.CodeUnit = 0xFFFD
    let replacementUTF8: [UTF8.CodeUnit] = [0xEF, 0xBF, 0xBD]
    let replacementScalar = UnicodeScalar(replacementUTF16)!
    let replacementCharacter = UTF8String.Character(replacementScalar)

    // This string contains a variety of non-ASCII characters, including
    // Unicode scalars that must be represented with a surrogate pair in
    // UTF16, grapheme clusters composed of multiple Unicode scalars, and
    // invalid UTF16 that should be replaced with replacement characters.

    let winterUTF16 = Array("🏂☃❅❆❄︎⛄️❄️".utf16) + [0xD83C, 0x0020, 0xDF67, 0xD83C]


    var winter = winterUTF16.withUnsafeBufferPointer {
      UTF8String.String._fromInvalidUTF16($0)
    }

    let winterInvalidUTF8: [UTF8.CodeUnit] = replacementUTF8 + ([0x20] as [UTF8.CodeUnit]) + replacementUTF8 + replacementUTF8
    let winterUTF8: [UTF8.CodeUnit] = [
      0xf0, 0x9f, 0x8f, 0x82, 0xe2, 0x98, 0x83, 0xe2, 0x9d, 0x85, 0xe2,
      0x9d, 0x86, 0xe2, 0x9d, 0x84, 0xef, 0xb8, 0x8e, 0xe2, 0x9b, 0x84,
      0xef, 0xb8, 0x8f, 0xe2, 0x9d, 0x84, 0xef, 0xb8, 0x8f
      ] + winterInvalidUTF8

    let winterUTF16Indices = Array(winter.utf16.indices)
    print(UTF8String.String(winter[winterUTF16Indices[1]]).asSwiftString)
    print(UTF8String.String.Index(winterUTF16Indices[1], within: winter))
    let winterUTF8Indices = Array(winter.utf8.indices)
    print(winter[winterUTF8Indices[1]])


    let summer = "school's out!" as UTF8String.String
    let summerBytes: [UInt8] = [
      0x73, 0x63, 0x68, 0x6f, 0x6f, 0x6c, 0x27, 0x73, 0x20, 0x6f, 0x75, 0x74, 0x21]

    // check the first three utf8 code units at the start of each utf16
    // code unit

    // Set up the parameters as explicit variables...
    let id = "legacy"
    func mapIndex(
      _ i: UTF8String.String.Index, _ v: UTF8String.String.UTF8View
    ) -> UTF8String.String.Index? {
      return i.samePosition(in: v)
    }

    let testArray = winter.utf16.indices.map {
      i16 in mapIndex(i16, winter.utf8).map {
        i8 in (0..<3).map {
          winter.utf8[winter.utf8.index(i8, offsetBy: $0)]
        }
      } ?? []
    }

    expectEqualSequence(
      [
        [0xf0, 0x9f, 0x8f],
        // does not align with any utf8 code unit
        id == "legacy" ? [] : replacementUTF8,
        [0xe2, 0x98, 0x83],
        [0xe2, 0x9d, 0x85],
        [0xe2, 0x9d, 0x86],
        [0xe2, 0x9d, 0x84],
        [0xef, 0xb8, 0x8e],
        [0xe2, 0x9b, 0x84],
        [0xef, 0xb8, 0x8f],
        [0xe2, 0x9d, 0x84],
        [0xef, 0xb8, 0x8f],
        replacementUTF8,
        [0x20] + replacementUTF8[0..<2],
        replacementUTF8,
        replacementUTF8
        ] as [[UTF8.CodeUnit]],
      testArray)//, sameValue: ==)

    expectNotNil(mapIndex(winter.utf16.endIndex, winter.utf8))
    expectEqual(
      winter.utf8.endIndex,
      mapIndex(winter.utf16.endIndex, winter.utf8)!)

    expectEqualSequence(
      summerBytes,
      summer.utf16.indices.map {
        summer.utf8[mapIndex($0, summer.utf8)!]
      }
    )

    expectNotNil(mapIndex(summer.utf16.endIndex, summer.utf8))
    expectEqual(
      summer.utf8.endIndex,
      mapIndex(summer.utf16.endIndex, summer.utf8)!)
  }

//  static var allTests = [
//    ("testExample", testExample),
//    ]

  func testMalformedBridged() {
    let badStr = NonContiguousNSString(
      [0xDE25, 0xD83D, 0xDC4D, 0x0061, 0x0062, 0x0063] as [UInt16])

    let correctedStr = "\u{FFFD}👍abc" as UTF8String.String
    expectPrototypeEquivalence(correctedStr, badStr as Swift.String)
    expectPrototypeEquivalence(
      UTF8String.String(_cocoaString: badStr), correctedStr.asSwiftString)
  }

  func testStringBreadcrumbs() {
    let stride = _StringBreadcrumbs.breadcrumbStride
    func validateBreadcrumbs(_ str: UTF8String.String) {
      let crumbs = _StringBreadcrumbs(str)
      expectEqual(str.utf16.count, crumbs.utf16Length)

      // Sanity check
      var utf16Array = Array(str.utf16)

      var idx = str.utf16.startIndex
      for crumbIdx in 0..<crumbs.crumbs.count {
        let crumb = crumbs.crumbs[crumbIdx]
        expectEqual(idx, crumb)
        if idx != str.utf16.endIndex {
          expectEqual(str.utf16[idx], utf16Array[crumbIdx * stride])
        }
        if crumb != crumbs.crumbs.last {
          idx = str.utf16.index(idx, offsetBy: stride)
        }
      }
    }

    let crumbsSmall = _StringBreadcrumbs(str)
    expectEqual(42, crumbsSmall.utf16Length)
    expectEqual(str.utf16.count, crumbsSmall.utf16Length)
    //expectEqual([str.startIndex], crumbsSmall.crumbs)

    let a = "a" as UTF8String.String
    let 日 = "日" as UTF8String.String

    validateBreadcrumbs("" as UTF8String.String)

    // Test our basic string
    validateBreadcrumbs(str)

    // Test just around the stride boundary
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride-1))
    validateBreadcrumbs(UTF8String.String(repeating: 日, count: stride-1))
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride))
    validateBreadcrumbs(UTF8String.String(repeating: 日, count: stride))
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride+1))
    validateBreadcrumbs(UTF8String.String(repeating: 日, count: stride+1))

    // Test just around multiples of stride boundaries
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride*2-1))
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride*2))
    validateBreadcrumbs(UTF8String.String(repeating: a, count: stride*2+1))

    // Test really large string
    validateBreadcrumbs(UTF8String.String(repeating: str, count: 128))
  }

  func testStringCompare() {
    func validateComparison(
      _ lhs: UTF8String.String, _ rhs: UTF8String.String
    ) {
      let swiftLHS = lhs.asSwiftString
      let swiftRHS = rhs.asSwiftString
      expectEqual(swiftLHS < swiftRHS, lhs < rhs)
      expectEqual(swiftLHS == swiftRHS, lhs == rhs)
      expectEqual(swiftLHS > swiftRHS, lhs > rhs)
    }

    let allStrings = [str, cafe, cafe2, leadingEmoji, abc, def]
    for s1 in allStrings {
      for s2 in allStrings {
        validateComparison(s1, s2)
      }
    }
  }

}

// The most simple subclass of NSString that CoreFoundation does not know
// about.
class NonContiguousNSString : NSString {
  override init() {
    _value = []
    super.init()
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("don't call this initializer")
  }
  required init(itemProviderData data: Data, typeIdentifier: Swift.String) throws {
    fatalError("don't call this initializer")
  }

  @nonobjc
  convenience init(_ utf8: [UInt8]) {
    var encoded = [UInt16]()
    let output: (UInt16) -> Void = { encoded.append($0) }
    let iterator = utf8.makeIterator()
    let hadError = transcode(
      iterator,
      from: UTF8.self,
      to: UTF16.self,
      stoppingOnError: true,
      into: output)
    expectFalse(hadError)
    self.init(encoded)
  }

  @nonobjc
  init(_ value: [UInt16]) {
    _value = value
    super.init()
  }

  @nonobjc
  convenience init(_ scalars: [UInt32]) {
    var encoded = [UInt16]()
    let output: (UInt16) -> Void = { encoded.append($0) }
    let iterator = scalars.makeIterator()
    let hadError = transcode(
      iterator,
      from: UTF32.self,
      to: UTF16.self,
      stoppingOnError: true,
      into: output)
    expectFalse(hadError)
    self.init(encoded)
  }

  required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
    fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
  }

  @objc(copyWithZone:)
  override func copy(with zone: NSZone?) -> Any {
    // Ensure that copying this string produces a class that CoreFoundation
    // does not know about.
    return self
  }

  @objc override var length: Int {
    return _value.count
  }

  @objc override func character(at index: Int) -> unichar {
    return _value[index]
  }

  var _value: [UInt16]
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

