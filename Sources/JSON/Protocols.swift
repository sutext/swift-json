//
//  Protocols.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//

import Foundation

// MARK: - Definition declaration

/// Simple JSON Key
/// Do not declare new conformances to this protocol;
/// they will not work as expected.
public protocol JSONKey:Codable{}
extension Int:JSONKey{} // Array subuscript
extension String:JSONKey{} // Dictionary subscript

/// Simple JSON Value
/// Do not declare new conformances to this protocol
/// they will not work as expected.
public protocol JSONValue:Codable{}
extension Int:JSONValue{}
extension Int8:JSONValue{}
extension Int16:JSONValue{}
extension Int32:JSONValue{}
extension Int64:JSONValue{}
extension UInt:JSONValue{}
extension UInt8:JSONValue{}
extension UInt16:JSONValue{}
extension UInt32:JSONValue{}
extension UInt64:JSONValue{}
extension Bool:JSONValue{}
extension Float:JSONValue{}
extension Double:JSONValue{}
extension CGFloat:JSONValue{}
extension String:JSONValue{}
extension JSON:JSONValue{}
extension Array:JSONValue where Element:JSONValue{}
extension Optional:JSONValue where Wrapped:JSONValue{}
extension Dictionary:JSONValue where Key==String,Value:JSONValue{}

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
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements.map(JSON.init))
    }
}
extension JSON:ExpressibleByDictionaryLiteral{
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        let obj = elements.reduce(into: Object()) {
            let value = JSON($1.1)
            if value != .null{
                $0[$1.0] = value
            }
        }
        self = .object(obj)
    }
}
extension JSON:CustomStringConvertible,CustomDebugStringConvertible{
    public var description: String{
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        if let data = try? encoder.encode(self),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "⚠️[ERROR] JSON encode error"
    }
    public var debugDescription: String{ description }
}
extension JSON:Equatable{
    public static func ==(lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs,rhs) {
        case (.null,.null):
            return true
        case let (.bool(lvalue),.bool(rvalue)):
            return lvalue == rvalue
        case let (.number(lvalue),.number(rvalue)):
            return lvalue == rvalue
        case let (.string(lvalue),.string(rvalue)):
            return lvalue == rvalue
        case (.array(let lhsary),.array(let rhsary)):
            return lhsary == rhsary
        case (.object(let lhsdic),.object(let rhsdic)):
            return lhsdic == rhsdic
        default:
            return false
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
            fatalError("JSONType(\(self)) and IndexType(\(i)) do not match")
        }
    }
    public subscript(position: Index) -> (JSONKey,JSON) {
        switch (self,position){
        case let (.array(ary),.array(idx)):
            return (idx,ary[idx])
        case let (.object(obj),.object(idx)):
            return obj[idx]
        case (.null,_),(.bool,_),(.number,_),(.string,_):
            return (0,.null)
        default:
            fatalError("JSONType(\(self)) and IndexType(\(position)) do not match")
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
            fatalError("JSONType(\(self)) and StartIndex(\(start)) and EndIndex(\(start)) do not match")
        }
    }
}
