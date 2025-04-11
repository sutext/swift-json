//
//  Getters.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//

import Foundation

// MARK: - JSON: Fast Access Safely getters

// It can only access with subscript, when dynamicMemberLookup has a confrontation with getters
public extension JSON{
    //int
    @inlinable var int:Int?{ number?.intValue }
    @inlinable var int8:Int8?{ number?.int8Value }
    @inlinable var int16:Int16?{  number?.int16Value }
    @inlinable var int32:Int32?{  number?.int32Value }
    @inlinable var int64:Int64?{ number?.int64Value }
    @inlinable var intValue:Int{ int ?? 0 }
    @inlinable var int8Value:Int8{  int8 ?? 0 }
    @inlinable var int16Value:Int16{ int16 ?? 0 }
    @inlinable var int32Value:Int32{ int32 ?? 0 }
    @inlinable var int64Value:Int64{ int64 ?? 0 }
    //uint
    @inlinable var uint:UInt?{ number?.uintValue }
    @inlinable var uint8:UInt8?{ number?.uint8Value }
    @inlinable var uint16:UInt16?{  number?.uint16Value }
    @inlinable var uint32:UInt32?{  number?.uint32Value }
    @inlinable var uint64:UInt64?{ number?.uint64Value }
    @inlinable var uintValue:UInt{ uint ?? 0 }
    @inlinable var uint8Value:UInt8{  uint8 ?? 0 }
    @inlinable var uint16Value:UInt16{ uint16 ?? 0 }
    @inlinable var uint32Value:UInt32{ uint32 ?? 0 }
    @inlinable var uint64Value:UInt64{ uint64 ?? 0 }
    //float
    @inlinable var float:Float?{ number?.floatValue }
    @inlinable var double:Double?{ number?.doubleValue }
    @inlinable var floatValue:Float{ float ?? 0 }
    @inlinable var doubleValue:Double{ double ?? 0 }
    //
    @inlinable var boolValue:Bool{ bool ?? false }
    @inlinable var arrayValue:Array{ array ?? [] }
    @inlinable var objectValue:Object{ object ?? [:] }
    @inlinable var stringValue:String{ string ?? "" }
    @inlinable var numberValue:Number{ number ?? 0 }
    
    //auto convert string and number to bool.
    @inlinable var bool:Bool?{
        switch self {
        case .bool(let bool):
            return bool
        case .number(let number):
            return number.boolValue
        case .string(let string):
            return Bool(string)
        default:
            return nil
        }
    }
    //auto convert string and bool to number.
    @inlinable var number:Number?{
        switch self {
        case .bool(let bool):
            return Number(value: bool)
        case .number(let number):
            return number
        case .string(let string):
            let number = NSDecimalNumber(string: string)
            if number == NSDecimalNumber.notANumber{
                return nil
            }
            return number
        default:
            return nil
        }
    }
    //auto convert bool and number to string.
    @inlinable var string:String?{
        switch self {
        case .bool(let bool):
            return bool ? "true" : "false"
        case .number(let number):
            return number.stringValue
        case .string(let string):
            return string
        default:
            return nil
        }
    }
    //strict array getter
    @inlinable var array:Array?{
        if case .array(let ary) = self { return ary }
        return nil
    }
    //strict object getter
    @inlinable var object:Object?{
        if case .object(let dic) = self {  return dic }
        return nil
    }
    //strict bool getter. The type conversion is not provided
    @inlinable var strictBool:Bool?{
        if case .bool(let value) = self {  return value }
        return nil
    }
    //strict number getter. The type conversion is not provided
    @inlinable var strictNumber:Number?{
        if case .number(let value) = self { return value }
        return nil
    }
    //strict string getter. The type conversion is not provided
    @inlinable var strictString:String?{
        if case .string(let value) = self {  return value }
        return nil
    }
}

// MARK: Type judgment
extension JSON{
    //strict type
    @inlinable var isNull:Bool{
        if case .null = self { return true }
        return false
    }
    //Strict type judgment
    @inlinable var isBool:Bool{
        if case .bool = self { return true }
        return false
    }
    //Strict type judgment
    @inlinable var isNumber:Bool{
        if case .number = self { return true }
        return false
    }
    //Strict type judgment
    @inlinable var isString:Bool{
        if case .string = self { return true }
        return false
    }
    //Strict type judgment
    @inlinable var isArray:Bool{
        if case .array = self { return true }
        return false
    }
    //Strict type judgment
    @inlinable var isObject:Bool{
        if case .object = self { return true }
        return false
    }
    /// Brief descriptions. only print the root element
    @inlinable var intro:String{
        switch self {
        case .null:
            return "JSON.null"
        case .bool(let bool):
            return "JSON.bool(\(bool))"
        case .array(let array):
            return "JSON.Array(\(array.count))"
        case .object(let object):
            return "JSON.Object(\(object.count))"
        case .number(let number):
            return "JSON.number(\(number))"
        case .string(let string):
            return "JSON.string(\"\(string)\")"
        }
    }
}

// MARK: - JSON: RawValue
extension JSON{
    /// Recover the original data structure
    ///
    ///     let json = JSON(["key":"value"])
    ///     if let dic = json.rawValue as? [AnyHashable:Any]{
    ///         print(dic)
    ///         thirdPartMethodd(dic:dic);
    ///     }
    /// - Note:`nil` is only obtained if `self` is `JSON.null`
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
            return value.mapValues { $0.rawValue }
        case .array(let value):
            return value.map{ $0.rawValue }
        }
    }
    /// The same as `rawValue`,but compact. Strip all null values.
    /// - SeeAlso: `rawValue`
    @inlinable public var compactValue:Any?{
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
            return value.compactMapValues { $0.compactValue }
        case .array(let value):
            return value.compactMap{ $0.compactValue }
        }
    }
    /// Convert to json data
    /// JSONSerialization is more efficient
    /// - Note:Got `nil`  only when `self` is `JSON.null`
    @inlinable public var rawData:Data?{
        guard let value = rawValue else{
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys,.fragmentsAllowed])
    }
    /// The same as `rawData` but compact.Strip all null values.
    /// - SeeAlso: `rawData`
    @inlinable public var compactData:Data?{
        guard let value = compactValue else{
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
    }
    /// Convert to json string use UTF8 encoding.
    /// - Note:Got `nil`  only when `self` is `JSON.null`
    @inlinable public var rawString: String?{
        guard let data = rawData else{
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else{
            return nil
        }
        return string
    }
    /// The same as `rawString` but compact.Strip all null values.
    /// - SeeAlso: `compactString`
    @inlinable public var compactString: String?{
        guard let data = compactData else{
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else{
            return nil
        }
        return string
    }
}
