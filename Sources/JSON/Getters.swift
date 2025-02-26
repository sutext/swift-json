//
//  Getters.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//

import Foundation

// MARK: - JSON: Fast Access Safely getters

/// It can only be reduced to subscipt, When dynamicMemberLookup has a confrontation with getters
public extension JSON{
    @inlinable var int8:Int8?{ number?.int8Value }
    @inlinable var int8Value:Int8{  int8 ?? 0 }
    @inlinable var int16:Int16?{  number?.int16Value }
    @inlinable var int16Value:Int16{ int16 ?? 0 }
    @inlinable var int32:Int32?{  number?.int32Value }
    @inlinable var int32Value:Int32{ int32 ?? 0 }
    @inlinable var int:Int?{ number?.intValue }
    @inlinable var intValue:Int{ int ?? 0 }
    @inlinable var int64:Int64?{ number?.int64Value }
    @inlinable var int64Value:Int64{ int64 ?? 0 }
    @inlinable var uint64:UInt64?{ number?.uint64Value }
    @inlinable var uint64Value:UInt64{ uint64 ?? 0 }
    @inlinable var float:Float?{ number?.floatValue }
    @inlinable var floatValue:Float{ float ?? 0 }
    @inlinable var double:Double?{ number?.doubleValue }
    @inlinable var doubleValue:Double{ double ?? 0 }
    
    @inlinable var boolValue:Bool{ bool ?? false }
    @inlinable var arrayValue:Array{ array ?? [] }
    @inlinable var objectValue:Object{ object ?? [:] }
    @inlinable var stringValue:String{ string ?? "" }
    @inlinable var numberValue:Number{ number ?? NSDecimalNumber.zero }
    
    @inlinable var array:Array?{
        if case .array(let ary) = self { return ary }
        return nil
    }
    @inlinable var object:Object?{
        if case .object(let dic) = self {  return dic }
        return nil
    }
    
    /// Safety Number access. Compatible with string and bool types
    ///
    ///     var json = JSON("123")
    ///     print(json.number) // 123
    ///     json = JSON(true)
    ///     print(json.number) // 1
    ///     var json = JSON()
    ///     print(json.number) // nil
    ///     json = JSON("a1231")
    ///     print(json.number) // nil
    ///     json = JSON([])
    ///     print(json.number) // nil
    ///     json = JSON([:])
    ///     print(json.number) // nil
    ///
    var number:Number?{
        switch self {
        case .bool(let value):
            return Number(value: value)
        case .number(let value):
            return value
        case .string(let value):
            let decimal = NSDecimalNumber(string: value)
            if decimal == NSDecimalNumber.notANumber {
                return nil
            }
            return decimal
        default:
            return nil
        }
    }
    
    /// Safety String access. Compatible with number types
    ///
    ///     var json = JSON("abc")
    ///     print(json.string) // "abc"
    ///     json = JSON(1)
    ///     print(json.string) // "1"
    ///     var json = JSON()
    ///     print(json.string) // nil
    ///     json = JSON([])
    ///     print(json.string) // nil
    ///     json = JSON([:])
    ///     print(json.string) // nil
    ///
    var string:String?{
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.stringValue
        case .bool(let value):
            return value ? "true" : "false"
        default:
            return nil
        }
    }
    /// Safety  Bool access. Compatible with string and number types
    /// We do not convert numbers to Booleans, Because that is understand without hesitation.
    /// NSNumber.boolValue treats 0 as false and non-0 as true, that is not safely
    ///
    ///     var json = JSON(true)
    ///     print(json.bool) // true
    ///     json = JSON(Int8(1))
    ///     print(json.bool) // true
    ///     json = JSON("true")
    ///     print(json.bool) // true
    ///     json = JSON("false")
    ///     print(json.bool) // false
    ///     json = JSON("1")
    ///     print(json.bool) // nil
    ///     json = JSON(1)
    ///     print(json.bool) // nil
    ///
    var bool:Bool?{
        switch self {
        case .bool(let value):
            return value
        case .string(let value):
            return Bool(value)
        default:
            return nil
        }
    }
}

// MARK: - JSON: RawValue
extension JSON{
    /// Convert to json string use UTF8 encoding.
    @inlinable public var rawString: String?{
        if let rawData, let str = String(data: rawData, encoding: .utf8){
            return str
        }
        return nil
    }
    /// Recover the original data structure
    ///
    ///     let json = JSON(["key":"value"])
    ///     if let dic = json.rawValue as? [AnyHashable:Any]{
    ///         print(dic)
    ///         thirdPartMethodd(dic:dic);
    ///     }
    ///
    @inlinable public var rawValue:Any?{
        switch self {
        case .bool(let value):
            return value
        case .number(let value):
            return value
        case .null:
            return nil
        case .string(let value):
            return value
        case .object(let value):
            return value.compactMapValues { $0.rawValue }
        case .array(let value):
            return value.map({ $0.rawValue })
        }
    }
    /// Convert to json data
    /// JSONSerialization is more efficient
    @inlinable public var rawData:Data?{
        if let rawValue{
            return try?  JSONSerialization.data(withJSONObject: rawValue, options: .sortedKeys)
        }
        return nil
    }
}
