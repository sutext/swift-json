//
//  JSON.swift
//
//  Created by supertext on 2023/2/1.
//

import Foundation

///
/// `JSON` is  not only a traditional json data structure, it's a generic data structure
/// So in many cases you can use `JSON` instead of `Any`
/// `JSON` implements standard protocols such as `RandomAccessCollection` `Subscript` `Codable` and so on
///
/// - Note: The `JSON` Object will filter  the key which value is null.  Set `null` or `nil` value to the `JSON` Object key  means delete it
/// - Note: When `Int` subscript access for `JSON` will substitute  `warning` for `Index out of bounds error`
/// - Note: `JSON(Int8(1)) and JSON(Int8(0))` will be save as `JSON.bool(true) an JSON.bool(false)`
///
@dynamicMemberLookup public enum JSON {
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
    static func parse(_ rawString:String)throws->JSON{
        return try JSON.parse(Data(rawString.utf8))
    }
    static func parse(_ rawData:Data)throws ->JSON{
        let obj = try JSONSerialization.jsonObject(with: rawData, options: [.allowFragments])
        return JSON(obj)
    }
    init(parse rawString: String?){
        guard let string = rawString,let json = try? JSON.parse(string) else {
            self = .null
            return
        }
        self = json
    }
    init(parse rawData: Data?){
        guard let data = rawData,let json = try? JSON.parse(data) else {
            self = .null
            return
        }
        self = json
    }
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
        case let value as [String: Any]:
            let result = value.reduce(into:Object()) { map, ele in
                let value = JSON(ele.value)
                if value != .null{
                    map[ele.key] = value
                }
            }
            self = .object(result)
        case let value as NSDictionary:
            let result = value.reduce(into:Object()) { map, ele in
                let value = JSON(ele.value)
                if let key = ele.key as? String,value != .null{
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
    public subscript(dynamicMember key:String) -> JSON {
        get { getValue(key)}
        set { setValue(newValue, forKey: key)}
    }
    public subscript(path: JSONKey...) -> JSON {
        get { self[path] }
        set { self[path] = newValue }
    }
    public subscript(path: [JSONKey]) -> JSON {
        get {
            switch path.count{
            case 0:
                return .null
            case 1:
                return self.getValue(path[0])
            default:
                return path.reduce(self){$0.getValue($1)}
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
    private func getValue(_ key:JSONKey)->JSON{
        switch (self,key){
        case let (.array(ary),idx as Int):
            return ary.count>idx ? ary[idx] : .null
        case let (.object(dic),str as String):
            return dic[str] ?? .null
        default:
            return .null
        }
    }
    private mutating func setValue(_ newValue:JSON,forKey key:JSONKey){
        switch key{
        case let idx as Int:
            guard case .array( var ary) = self else{
                print("⚠️⚠️[JSON] Self type must be `JSON.Array` when key:(\(idx)) is Int")
                return
            }
            if ary.count > idx{
                ary[idx] = newValue
                self = .array(ary)
            }else{
                print("⚠️⚠️[JSON] Index(\(idx)) out of bounds(\(ary.count))")
            }
        case let str as String:
            guard case .object( var obj) = self else{
                print("⚠️⚠️[JSON] Self type must be `JSON.Object` when key:(\(str)) is String")
                return
            }
            if case .null = newValue {
                obj[str] = nil
            }else{
                obj[str] = newValue
            }
            self = .object(obj)
        default:
            print("⚠️⚠️Declare new conformances to `JSONKey` protocol will not work!")
        }
    }
}
