//
//  Number.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//
import Foundation

extension JSON.Number{
    /// is bool or not
    @inlinable public var isBool:Bool{
        octype == .bool && (int8Value == 0 || int8Value == 1)
    }
    // get objc type for current number
    @inlinable public var octype:OCType{ OCType(self) }
    /// enum some objc type of number
    public struct OCType:RawRepresentable,Codable,Equatable,Hashable{
        public var rawValue: CChar
        public init(rawValue: CChar) {
            self.rawValue = rawValue
        }
        public init(_ number:JSON.Number) {
            self.init(rawValue: number.objCType.pointee)
        }
        public static let bool     = OCType(.init(value:true))       // Bool 99
        public static let int8     = OCType(.init(value:Int8.max))   // Int8 99
        public static let int16    = OCType(.init(value:Int16.max))  // Int16 UInt8 115
        public static let int32    = OCType(.init(value:Int32.max))  // Int32 UInt16 105
        public static let int64    = OCType(.init(value:Int64.max))  // Int64 UInt32 113
        public static let uint64   = OCType(.init(value:UInt64.max)) // UInt64 81
        public static let float    = OCType(.init(value:Float(0.0))) // Float 100
        public static let double   = OCType(.init(value:Double(0.0)))// Double 102
    }
}
