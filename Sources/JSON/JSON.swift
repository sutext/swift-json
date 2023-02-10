//
//  JSON.swift
//
//  Created by supertext on 2023/2/1.
//
///
/// `JSON` is  not only a traditional json data structure, it's a generic data structure
/// So in many cases you can use `JSON` instead of `Any`
/// `JSON` implements standard protocols such as `Collection` `Subscript` `Codable` and so on
///
/// - Note: The `JSON` Object will filter  the key which value is null.  Set `null` or `nil` value to the `JSON` Object key  means delete it
/// - Note: When `Int` subscript access for `JSON` will substitute  `warning` for `Index out of bounds error`
/// - Note: `JSON(Int8(1)) and JSON(Int8(0))` will be save as `JSON.bool(true) an JSON.bool(false)`
///
///
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

@dynamicMemberLookup public enum JSON {
    case null
    case bool(Bool)
    case array(Array)
    case object(Object)
    case string(String)
    case number(NSNumber)
    public typealias Array = [JSON]
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
        case let value as NSNumber:
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
    /// Describes the JSON data type
    @inlinable func type() -> String{
        switch self{
        case .null:     return "null"
        case .bool:     return "bool"
        case .array:    return "array"
        case .object:   return "object"
        case .string:   return "string"
        case .number:   return "number"
        }
    }
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

// MARK: Standard protocol implementation

extension JSON:ExpressibleByNilLiteral{
    public init(nilLiteral: ()) {
        self = .null
    }
}
extension JSON:ExpressibleByFloatLiteral{
    public init(floatLiteral value: FloatLiteralType) {
        self = .number(NSNumber(value:value))
    }
}
extension JSON:ExpressibleByIntegerLiteral{
    public init(integerLiteral value: IntegerLiteralType) {
        self = .number(NSNumber(value:value))
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
            fatalError("JSONType(\(self) and IndexType(\(i) do not match")
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
            fatalError("JSONType(\(self) and IndexType(\(position) do not match")
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
            fatalError("JSONType(\(self) and StartIndex(\(start) and EndIndex(\(start) do not match")
        }
    }
}
// MARK: - JSON: Subscript

extension JSON{
    public subscript(key:JSONKey)->JSON{
        get{ getValue(key) }
        set{ setValue(newValue, forKey: key) }
    }
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
            return path.reduce(self){$0[$1]}
        }
        set {
            switch path.count {
            case 0:
                return
            case 1:
                self[path[0]] = newValue
            default:
                var aPath = path
                aPath.remove(at: 0)
                var next = self[path[0]]
                next[aPath] = newValue
                self[path[0]] = next
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
        switch (key,self){
        case (let idx as Int, .array(var ary)):
            if ary.count > idx{
                ary[idx] = newValue
                self = .array(ary)
            }else{
                print("⚠️⚠️Index out of bounds. Index:\(idx) arrayCount:\(ary.count)")
            }
        case (let str as String, .object(var obj)):
            if case .null = newValue {
                obj[str] = nil
            }else{
                obj[str] = newValue
            }
            self = .object(obj)
        default:
            print("⚠️⚠️JSON type:\(self.type()) and JSONKey \(key)(type:\(Swift.type(of: key))) do not match!")
        }
    }
}
// MARK: - JSON: Fast Access Safely getters
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
    @inlinable var numberValue:NSNumber{ number ?? NSDecimalNumber.zero }
    
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
    var number:NSNumber?{
        switch self {
        case .bool(let value):
            return NSNumber(value: value)
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
        default:
            return nil
        }
    }
    /// Safety  Bool access. Compatible with string and number types
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
        case .number(let value):
            return value.isBool ? value.boolValue : nil
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
        if let data = rawData, let str = String(data: data, encoding: .utf8){
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
    @inlinable public var rawData:Data?{
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try? encoder.encode(self)        
    }
}

// MARK: - JSON: Codable
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
            self = .number(NSNumber(value: value))
            return
        }
        if let value = try? container.decode(UInt64.self) {
            self = .number(NSNumber(value: value))
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .number(NSNumber(value: value))
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
extension NSNumber{
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
        public init(_ number:NSNumber) {
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
