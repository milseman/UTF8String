// Needed for bridging
import Foundation

// Mockups from Builtin.swift
@inlinable
internal var _objCTaggedPointerBits: UInt {
  @inline(__always) get { return UInt(_swift_BridgeObject_TaggedPointerBits) }
}
@inlinable @inline(__always)
internal func _isObjCTaggedPointer(_ x: AnyObject) -> Bool {
  return (Builtin.reinterpretCast(x) & _objCTaggedPointerBits) != 0
}
@inlinable @inline(__always)
internal func _isObjCTaggedPointer(_ x: UInt) -> Bool {
  return (x & _objCTaggedPointerBits) != 0
}
public func _branchHint(_ actual: Bool, expected: Bool) -> Bool {
  return actual
}

// Mockups from Integers
extension BinaryInteger {
  @usableFromInline
  internal func _description(radix: Int, uppercase: Bool) -> String {
    let swiftStr = Swift.String(self, radix: radix, uppercase: uppercase)
    return String(swiftStr)
  }
}

extension String {
  @inlinable // FIXME(sil-serialize-all)
  public init<Subject>(describing instance: Subject) {
    self.init(Swift.String(describing: instance))
  }
}

// Mockup from Array shared code
@inlinable
internal func _growArrayCapacity(_ capacity: Int) -> Int {
  return capacity * 2
}

// Forward conformance to stdlib native ones
//extension String: Swift._ExpressibleByBuiltinUnicodeScalarLiteral {}
//extension String: Swift._ExpressibleByBuiltinExtendedGraphemeClusterLiteral {}
//extension String: Swift._ExpressibleByBuiltinUTF16StringLiteral {}
//extension String: Swift._ExpressibleByBuiltinStringLiteral {}
//extension String: Swift.ExpressibleByUnicodeScalarLiteral {}
//extension String: Swift.ExpressibleByExtendedGraphemeClusterLiteral {}
//extension String: Swift.ExpressibleByStringLiteral {}
//
//extension String: Swift.CustomDebugStringConvertible {
//  public var debugDescription: Swift.String {
//    return self.asSwiftString.debugDescription
//  }
//}

// Mockup from Assert.swift
//@inlinable @_transparent
//public func fatalError(
//  _ message: @autoclosure () -> String = String(),
//  file: StaticString = #file, line: UInt = #line
//) -> Never {
//  Swift.fatalError()
//}
@inlinable @_transparent
public func _sanityCheck(
  _ condition: @autoclosure () -> Bool, _ message: Swift.StaticString = Swift.StaticString(),
  file: StaticString = #file, line: UInt = #line
) {
  #if INTERNAL_CHECKS_ENABLED
  // NOTE: We're just mocking stuff up, not honoring configuration
  _precondition(condition, message, file: file, line: line)
  #endif
}
public func _sanityCheckFailure(
  _ message: StaticString = StaticString(),
  file: StaticString = #file, line: UInt = #line
) -> Never {
  // NOTE: We're just mocking stuff up, not honoring configuration
  _preconditionFailure(message, file: file, line: line)
}

public func _precondition(
  _ condition: @autoclosure () -> Bool, _ message: StaticString = StaticString(),
  file: StaticString = #file, line: UInt = #line
) {
  guard condition() else {
    _preconditionFailure(message, file: file, line: line)
  }
}
public func _preconditionFailure(
  _ message: StaticString = StaticString(),
  file: StaticString = #file, line: UInt = #line
) -> Never {
  Swift.fatalError(message.description, file: file, line: line)
}
public func _debugPrecondition(
  _ condition: @autoclosure () -> Bool, _ message: StaticString = StaticString(),
  file: StaticString = #file, line: UInt = #line
  ) {
  // NOTE: We're just mocking stuff up, not honoring configuration
  _precondition(condition, message, file: file, line: line)
}
//public func _debugPreconditionFailure(
//  _ message: StaticString = StaticString(),
//  file: StaticString = #file, line: UInt = #line
//  ) -> Never {
//  if _slowPath(_isDebugAssertConfiguration()) {
//    _precondition(false, message, file: file, line: line)
//  }
//  _conditionallyUnreachable()
//}



// Mock unwrapping
extension Optional {
  public var _unsafelyUnwrappedUnchecked: Wrapped {
    @inline(__always)
    get {
      if let x = self {
        return x
      }
      _sanityCheckFailure("_unsafelyUnwrappedUnchecked of nil optional")
    }
  }
}

// Mockup from UnicodeScalar.swift
extension Unicode.Scalar {
  public init(_unchecked v: UInt32) {
    self = Unicode.Scalar(v)._unsafelyUnwrappedUnchecked
  }
}

import SwiftShims

extension String {
  // Hack to create our new String from toolchain's String
  public init(fromSwiftString s: Swift.StaticString) {
    guard s.hasPointerRepresentation else { fatalError("this hack is for big literals") }
    let bufPtr = UnsafeBufferPointer(
      start: s.utf8Start, count: s.utf8CodeUnitCount)
    self.init(_StringGuts(bufPtr, isKnownASCII: s.isASCII))
  }
  public init(_ s: Swift.String) {
    let codeUnits = Array(s.utf8)
    self = codeUnits.withUnsafeBufferPointer { String._uncheckedFromUTF8($0) }
  }

  public var asSwiftString: Swift.String {
    return Swift.String(decoding: self.utf8, as: UTF8.self)
  }

  // From Mirror.swift
  public init<Subject>(reflecting subject: Subject) {
    self.init(Swift.String(reflecting: subject))
  }

}

public func print(
  _ items: Any...,
  separator: String = " ",
  terminator: String = "\n",
  to output: inout String
) {
  var swiftStr = Swift.String()
  var prefix: Swift.String = ""
  for item in items {
    Swift.print(prefix, separator: "", terminator: "", to: &swiftStr)
    Swift.print(
      item, separator: "", terminator: Swift.String(), to: &swiftStr)
    prefix = separator.asSwiftString
  }
  Swift.print(
    "", separator: "", terminator: terminator.asSwiftString, to: &swiftStr)
  output += String(swiftStr)
}

//// Mock up print(str)
//public func print(_ s: String) {
//  print(s.asSwiftString)
//}
//
//// Mock up dump(str)
//public func dump(_ s: String) {
//  dump(s.asSwiftString)
//}


/// Returns `true` if `object` is uniquely referenced.
/// This provides sanity checks on top of the Builtin.
@_transparent
public // @testable
func _isUnique_native<T>(_ object: inout T) -> Bool {
  // This could be a bridge object, single payload enum, or plain old
  // reference. Any case it's non pointer bits must be zero, so
  // force cast it to BridgeObject and check the spare bits.

  return Bool(Builtin.isUnique_native(&object))
}

// HACK HACK HACK: The below is particularly bad, but alternative is to pull
// in encoders...
extension _ValidUTF8Buffer {
  public var _biasedBits: Storage { return Builtin.reinterpretCast(self) }

  internal init(_biasedBits: Storage) {
    self = Builtin.reinterpretCast(_biasedBits)
  }

  public static var encodedReplacementCharacter : _ValidUTF8Buffer {
    return _ValidUTF8Buffer(_biasedBits: 0xBD_BF_EF &+ 0x01_01_01)
  }

  public var _bytes: (bytes: UInt64, count: Int) {
    let count = self.count
    let mask: UInt64 = 1 &<< (UInt64(truncatingIfNeeded: count) &<< 3) &- 1
    let unbiased = UInt64(truncatingIfNeeded: _biasedBits) &- 0x0101010101010101
    return (unbiased & mask, count)
  }
}

// Access the underlying code units
extension Unicode.Scalar {
  // Access the scalar as encoded in UTF-16
  internal func withUTF16CodeUnits<Result>(
    _ body: (UnsafeBufferPointer<UInt16>) throws -> Result
    ) rethrows -> Result {
    var codeUnits: (UInt16, UInt16) = (self.utf16[0], 0)
    let utf16Count = self.utf16.count
    if utf16Count > 1 {
      _sanityCheck(utf16Count == 2)
      codeUnits.1 = self.utf16[1]
    }
    return try Swift.withUnsafePointer(to: &codeUnits) {
      return try $0.withMemoryRebound(to: UInt16.self, capacity: 2) {
        return try body(UnsafeBufferPointer(start: $0, count: utf16Count))
      }
    }
  }

  // Access the scalar as encoded in UTF-8
  @inlinable
  internal func withUTF8CodeUnits<Result>(
    _ body: (UnsafeBufferPointer<UInt8>) throws -> Result
    ) rethrows -> Result {
    let encodedScalar = UTF8.encode(self)!
    var (codeUnits, utf8Count) = encodedScalar._bytes
    return try Swift.withUnsafePointer(to: &codeUnits) {
      return try $0.withMemoryRebound(to: UInt8.self, capacity: 4) {
        return try body(UnsafeBufferPointer(start: $0, count: utf8Count))
      }
    }
  }
}
extension Unicode.Scalar {
  @inlinable // FIXME(sil-serialize-all)
  internal static var _replacementCharacter: Unicode.Scalar {
    return Unicode.Scalar(0xFFFD)!
  }
}
extension UTF16 {
  @inlinable // FIXME(sil-serialize-all)
  internal static var _replacementCodeUnit: UInt16 {
    return 0xFFFD
  }
}

// NSStringAPI.swift
extension String {
  public init?(
    cString: UnsafePointer<CChar>,
    encoding enc: Swift.String.Encoding
    ) {
    if let ns = NSString(cString: cString, encoding: enc.rawValue) {
      self = String(_cocoaString: ns)
    } else {
      return nil
    }
  }

}

// Access _distance, _index, etc.
extension BidirectionalCollection {
  /// Do not use this method directly; call advanced(by: n) instead.
  @inlinable
  @inline(__always)
  internal func _advanceForward(_ i: Index, by n: Int) -> Index {
    _precondition(n >= 0,
                  "Only BidirectionalCollections can be advanced by a negative amount")

    var i = i
    for _ in stride(from: 0, to: n, by: 1) {
      formIndex(after: &i)
    }
    return i
  }

  /// Do not use this method directly; call advanced(by: n, limit) instead.
  @inlinable
  @inline(__always)
  internal func _advanceForward(
    _ i: Index, by n: Int, limitedBy limit: Index
    ) -> Index? {
    _precondition(n >= 0,
                  "Only BidirectionalCollections can be advanced by a negative amount")

    var i = i
    for _ in stride(from: 0, to: n, by: 1) {
      if i == limit {
        return nil
      }
      formIndex(after: &i)
    }
    return i
  }

  @inlinable // FIXME(sil-serialize-all)
  public func _index(_ i: Index, offsetBy n: Int) -> Index {
    if n >= 0 {
      return _advanceForward(i, by: n)
    }
    var i = i
    for _ in stride(from: 0, to: n, by: -1) {
      formIndex(before: &i)
    }
    return i
  }

  @inlinable // FIXME(sil-serialize-all)
  public func _index(
    _ i: Index, offsetBy n: Int, limitedBy limit: Index
    ) -> Index? {
    if n >= 0 {
      return _advanceForward(i, by: n, limitedBy: limit)
    }
    var i = i
    for _ in stride(from: 0, to: n, by: -1) {
      if i == limit {
        return nil
      }
      formIndex(before: &i)
    }
    return i
  }

  @inlinable // FIXME(sil-serialize-all)
  internal func _distance(from start: Index, to end: Index) -> Int {
    var start = start
    var count = 0

    if start < end {
      while start != end {
        count += 1
        formIndex(after: &start)
      }
    }
    else if start > end {
      while start != end {
        count -= 1
        formIndex(before: &start)
      }
    }

    return count
  }
}

/// Tell the optimizer that this code is unreachable if this builtin is
/// reachable after constant folding build configuration builtins.
@usableFromInline @_transparent
internal func _conditionallyUnreachable() -> Never {
  Builtin.conditionallyUnreachable()
}
