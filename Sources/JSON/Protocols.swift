//
//  Protocols.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//

import Foundation

// MARK: Standard protocol implementation

extension JSON:ExpressibleByNilLiteral{
    public init(nilLiteral: ()) {
        self = .null
    }
}
extension JSON:ExpressibleByFloatLiteral{
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(Number(value:value))
    }
}
extension JSON:ExpressibleByIntegerLiteral{
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(Number(value:value))
    }
}
extension JSON:ExpressibleByBooleanLiteral{
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}
extension JSON:ExpressibleByStringInterpolation{
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(stringInterpolation: DefaultStringInterpolation) {
        self = .string(stringInterpolation.description)
    }
}
extension JSON:ExpressibleByArrayLiteral{
    public init(arrayLiteral elements: Any?...) {
        self = .array(elements.map{JSON($0)})
    }
}
extension JSON:ExpressibleByDictionaryLiteral{
    public init(dictionaryLiteral elements: (String,Any?)...) {
        let obj = elements.reduce(into: Object()) {
            $0[$1.0] = JSON($1.1)
        }
        self = .object(obj)
    }
}
extension JSON:CustomStringConvertible,CustomDebugStringConvertible{
    /// Brief descriptions. only print the root element
    @inlinable public var intro:String{
        switch self {
        case .null:
            return "JSON.null"
        case .bool(let bool):
            return "JSON.bool(\(bool))"
        case .array(let array):
            return "JSON.Array(\(array.count) elements)"
        case .object(let object):
            return "JSON.Object(\(object.count) key-pairs)"
        case .number(let number):
            return "JSON.number(\(number))"
        case .string(let string):
            return "JSON.string(\"\(string)\")"
        }
    }
    public var description: String{
        guard let rawValue else{
            return "null"
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rawValue, options: [.sortedKeys,.prettyPrinted,.fragmentsAllowed]) else{
            return "⚠️⚠️[JSON ERROR] Invalid JSON Object"
        }
        guard let str = String(data: data, encoding: .utf8) else{
            return "⚠️⚠️[JSON ERROR] Invalid UTF-8 Data"
        }
        return str
    }
    public var debugDescription: String{ description }
}

/// `JSONKey` Is the protoco of`JSON` subscript key.  Only `Int` and `String`can conform this protocol
/// - Important: Do not declare new conformances to this protocol, they will not work as expected.
public protocol JSONKey:Codable,Hashable,Sendable{}
extension Int:JSONKey{}
extension String:JSONKey{}
extension JSONKey{
    var intKey: Int?{
        switch self{
        case let int as Int:
            return int
        case let str as String:
            return Int(str)
        default:
            return nil
        }
    }
    var strKey: String?{
        switch self{
        case let int as Int:
            return String(int)
        case let str as String:
            return str
        default:
            return nil
        }
    }
}

extension JSON:RandomAccessCollection{
    public enum Index:Comparable{
        case none
        case array(Array.Index)
        case object(Object.Index)
    }
    public var startIndex: Index {
        switch self{
        case .array(let ary):
            return .array(ary.startIndex)
        case .object(let obj):
            return .object(obj.startIndex)
        default:
            return .none
        }
    }
    public var endIndex: Index {
        switch self{
        case .array(let ary):
            return .array(ary.endIndex)
        case .object(let obj):
            return .object(obj.endIndex)
        default:
            return .none
        }
    }
    public func index(before i: Index) -> Index {
        index(i, offsetBy: -1)
    }
    public func index(after i: Index) -> Index {
        index(i, offsetBy: 1)
    }
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        switch (self,i){
        case let (.array(ary),.array(idx)):
            return .array(ary.index(idx, offsetBy: distance))
        case let (.object(obj),.object(idx)):
            return .object(obj.index(idx, offsetBy: distance))
        case (.null,_),(.bool,_),(.number,_),(.string,_):
            return .none
        default:
            fatalError("\(self.intro) and Index(\(i)) do not match")
        }
    }
    public subscript(position: Index) -> (any JSONKey,JSON) {
        switch (self,position){
        case let (.array(ary),.array(idx)):
            return (idx,ary[idx])
        case let (.object(obj),.object(idx)):
            return obj[idx]
        case (.null,_),(.bool,_),(.number,_),(.string,_):
            return (0,.null)
        default:
            fatalError("\(self.intro) and Index(\(position)) do not match")
        }
    }
    public func distance(from start: Index, to end: Index) -> Int {
        switch (self,start,end){
        case let (.array(ary),.array(s),.array(e)):
            return ary.distance(from: s, to: e)
        case let (.object(obj),.object(s),.object(e)):
            return obj.distance(from: s, to: e)
        case (.null,_,_),(.bool,_,_),(.number,_,_),(.string,_,_):
            return 0
        default:
            fatalError("\(self.intro) and StartIndex(\(start)) and EndIndex(\(start)) do not match")
        }
    }
}
extension JSON:Hashable{
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null:
            Optional<JSON>.none.hash(into: &hasher)
        case .bool(let bool):
            bool.hash(into: &hasher)
        case .array(let array):
            array.hash(into: &hasher)
        case .object(let object):
            object.hash(into: &hasher)
        case .number(let number):
            number.hash(into: &hasher)
        case .string(let string):
            string.hash(into: &hasher)
        }
    }
}

