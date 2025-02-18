//
//  Codable.swift
//  swift-json
//
//  Created by supertext on 2025/2/18.
//

import Foundation

extension JSON: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        if let value = try? container.decode(Int64.self) {
            self = .number(Number(value: value))
            return
        }
        if let value = try? container.decode(UInt64.self) {
            self = .number(Number(value: value))
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .number(Number(value: value))
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Array.self) {
            self = .array(value)
            return
        }
        if let value = try? container.decode(Object.self) {
            self = .object(value.filter{ $0.value != .null })
            return
        }
        self = .null
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .number(let number):
            switch  number.octype{
            case .double,.float:
                try container.encode(number.doubleValue)
            case .uint64:
                try container.encode(number.uint64Value)
            default:
                try container.encode(number.int64Value)
            }
        case .string(let string):
            try container.encode(string)
        case .array(let ary):
            try container.encode(ary)
        case .object(let dic):
            try container.encode(dic.filter{ $0.value != .null })
        }
    }
}
