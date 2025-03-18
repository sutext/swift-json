//
//  JSON.swift
//
//  Created by supertext on 2023/2/1.
//

import Foundation

///
/// `JSON` is  not only a traditional json data structure, it's a generic data structure. So in many cases you can use `JSON` instead of `Any`
/// `JSON` implements standard protocols such as `RandomAccessCollection` `Subscript` `Codable` and so on
///
/// - Note: When `Int` subscript write for `JSON.Array` will substitute  `warning` for `Index out of bounds error`
/// - Note: It can only be reduced to subscipt, When dynamicMemberLookup has a confrontation with getters
/// - Important: `JSON(Int8(1)) and JSON(Int8(0))` will be save as `JSON.bool(true) an JSON.bool(false)`,but `JSON(Int(8)).int8Value still right`
///
@dynamicMemberLookup public enum JSON:Sendable {
    case null
    case bool(Bool)
    case array(Array)
    case object(Object)
    case number(Number)
    case string(String)
    public typealias Array = [JSON]
    public typealias Number = NSNumber
    public typealias Object = [String:JSON]
}

// MARK: - Initializations
public extension JSON{
    /// Parse string to `JSON`
    /// - Parameters:
    ///    - rawString: raw data to be parse
    /// - Note: Use  getter`JSON.rawString` to recover raw string.
    /// - Important: Use `JSON(rawSttring)`directly,will got a simple string value as `JSON.string(rawString)`.
    ///
    static func parse(_ rawString:String)throws->JSON{
        return try JSON.parse(Data(rawString.utf8))
    }
    /// Parse data to `JSON`
    /// - Parameters:
    ///    - rawData: raw data to be parse
    /// - Note: use  getter`JSON.rawData` to recover raw data.
    /// - Important: Use`JSON(rawData)` directly .will got a `null` value as `JSON.null`.
    ///
    static func parse(_ rawData:Data)throws ->JSON{
        let obj = try JSONSerialization.jsonObject(with: rawData, options: [.allowFragments])
        return JSON(obj)
    }
    /// Parse string to `JSON`
    /// - Parameters:
    ///    - rawString: raw data to be parse
    /// - Note: use  getter`JSON.rawString` to recover raw string.
    /// - Important: Use `JSON(rawSttring)`directly,will got a simple string value as `JSON.string(rawString)`.
    ///
    init(parse rawString: String?){
        guard let string = rawString,let json = try? JSON.parse(string) else {
            self = .null
            return
        }
        self = json
    }
    /// Parse data to `JSON`
    /// - Parameters:
    ///    - rawData: raw data to be parse
    /// - Note: use  getter`JSON.rawData` to recover raw data.
    /// - Important: Use`JSON(rawData)` directly .will got a `null` value as `JSON.null`.
    ///
    init(parse rawData: Data?){
        guard let data = rawData,let json = try? JSON.parse(data) else {
            self = .null
            return
        }
        self = json
    }
    /// Converts any value to `JSON`
    /// - Parameters:
    ///    - rawValue: any value that conformances to `JSONValue` otherwise got `null`
    /// - Note: Use  getter`JSON.rawValue` to recover raw value.
    ///
    /// - Important: Use `JSON(rawData)` directly,  will got a `null` value as `JSON.null`.
    /// So you must parse it as `JSON(parse:rawData)` or `JSON.parse(rawData)`.
    /// - Important: Use  `JSON(rawSttring)`directly, will got a simple string value as `JSON.string(rawString)`.
    /// So you must parse it as `JSON(parse:rawSttring)` or `JSON.parse(rawSttring)`.
    ///
    init(_ rawValue:Any?=nil){
        guard let json = rawValue else {
            self = .null
            return
        }
        if json is NSNull {
            self = .null
            return
        }
        switch json {
        case let value as JSON:
            self = value
        case let value as String:
            self = .string(value)
        case let value as Number:
            if value.isBool {
                self = .bool(value.boolValue)
            }else{
                self = .number(value)
            }
        case let value as [Any]:
            self = .array(value.map(JSON.init))
        case let value as NSArray:
            self = .array(value.map(JSON.init))
        case let value as Set<AnyHashable>:
            self = .array(value.map(JSON.init))
        case let value as [String: Any]:
            let result = value.reduce(into:Object()) { map, ele in
                map[ele.key] = JSON(ele.value)
            }
            self = .object(result)
        case let value as NSDictionary:
            let result = value.reduce(into:Object()) { map, ele in
                let value = JSON(ele.value)
                if let key = ele.key as? String{
                    map[key] = value
                }
            }
            self = .object(result)
        default:
            self = .null
        }
    }
}
// MARK: - Usefull Methods
public extension JSON{
    /// merge values from other into current
    ///
    /// - Parameters:
    ///    - from: The other json that will be merged
    ///
    mutating func merge(from other:JSON){
        switch (self,other) {
        case (.array(let thisary),.array(let otherary)):
            self = .array(thisary + otherary)
        case (.object(var thisdic),.object(let otherdic)):
            for (key,value) in otherdic{
                if var thisval = thisdic[key]{
                    thisval.merge(from:value)
                    thisdic[key] = thisval
                }else{
                    thisdic[key] = value
                }
            }
            self = .object(thisdic)
        default:
            self = other
        }
    }
    /// merge values from other into current
    ///
    /// - Parameters:
    ///    - from: The other json that will be merged
    ///
    /// - Returns: A new merged json
    @inlinable func merged(from other:JSON) -> JSON{
        var result = self
        result.merge(from: other)
        return result
    }
}
// MARK: - JSON: Subscript

extension JSON{
    /// Like `removeValue(forKey:)`in `Dictionary`
    /// Unlike `Dictionary` set nil value with subscirpt will not remove the key.
    ///
    ///     var json = JSON(["key":"value"])
    ///     json.key = .null // set JSON.null for key
    ///     json.key = nil // set JSON.null for key
    ///     print(json.count) // 1
    ///     json.removeValue(forKey:"key") // will remove the key
    ///     print(json.count) // 0
    ///
    public mutating func removeValue(forKey:String){
        guard case .object(var obj) = self else{
            return
        }
        obj.removeValue(forKey: forKey)
        self = .object(obj)
    }
    public subscript(dynamicMember key:String) -> JSON {
        get { getValue(key)}
        set { setValue(newValue, forKey: key)}
    }
    public subscript(path: (any JSONKey)...) -> JSON {
        get { self[path] }
        set { self[path] = newValue }
    }
    public subscript(path: [any JSONKey]) -> JSON {
        get {
            switch path.count{
            case 0:
                return .null
            case 1:
                return self.getValue(path[0])
            default:
                return path.reduce(self){ $0.getValue($1) }
            }
        }
        set {
            switch path.count {
            case 0:
                return
            case 1:
                self.setValue(newValue, forKey: path[0])
            default:
                var aPath = path
                let key0 = aPath.remove(at: 0)
                var value0 = self.getValue(key0)
                value0[aPath] = newValue
                self.setValue(value0, forKey: key0)
            }
        }
    }
    private func getValue(_ key:any JSONKey)->JSON{
        switch self{
        case .array(let ary):
            guard let idx = key.intKey else{
                return .null
            }
            guard ary.count > idx else{
                return .null
            }
            return ary[idx]
        case .object(let obj):
            guard let str = key.strKey else{
                print("⚠️⚠️[JSON] Invalid JSONKey implements. Do not declare new conformances to JSONKey ")
                return .null
            }
            return obj[str] ?? .null
        default:
            print("⚠️⚠️[JSON] Only `JSON.Array` and `JSON.Object` have subscript properties")
            return .null
        }
    }
    private mutating func setValue(_ newValue:JSON,forKey key:any JSONKey){
        switch self {
        case .array(var ary):
            guard let idx = key.intKey else{
                print("⚠️⚠️[JSON] JSONKey must be able convert to `Int` when Self type is `JSON.Array`")
                return
            }
            guard ary.count > idx else{
                print("⚠️⚠️[JSON] Index(\(idx)) out of bounds(\(ary.count))")
                return
            }
            ary[idx] = newValue
            self = .array(ary)
        case .object(var obj):
            guard let str = key.strKey else{
                print("⚠️⚠️[JSON] Invalid JSONKey implements. Do not declare new conformances to JSONKey")
                return
            }
            obj[str] = newValue
            self = .object(obj)
        default:
            print("⚠️⚠️[JSON] Self type must be `JSON.Object` or `JSON.Array`")
        }
    }
}
