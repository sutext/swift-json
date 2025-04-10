import XCTest
@testable import JSON

final class JsonTests: XCTestCase {
    func testUsage() throws{
        let jsonString = "{\"b0\":0,\"b1\":true,\"b2\":125,\"b3\":\"true\",\"b4\":1}"
        let json = JSON(parse: jsonString)
        XCTAssertEqual(json.rawString, jsonString) // parse rawString
        let decodeJson = try? JSON.parse(json.rawData!) // parse rawData
        XCTAssertEqual(json, decodeJson)
        XCTAssertEqual(decodeJson?.rawString, jsonString)
        let rawJson = JSON(json.rawValue) // init rawValue
        XCTAssertEqual(json, rawJson)
        XCTAssertEqual(NSNumber.OCType.bool, NSNumber.OCType.int8)
        print(NSNumber.OCType.int64)
        print(NSNumber.OCType.uint64)
        print("Int8:",NSNumber(value: Int8.max).octype)
        print("UInt8:",NSNumber(value: UInt8(Int8.max)+1).octype)
        print("Int16:",NSNumber(value: Int16.max).octype)
        print("UInt16:",NSNumber(value: UInt16(Int16.max)+1).octype)
        print("Int32:",NSNumber(value: Int32.max).octype)
        print("UInt32:",NSNumber(value: UInt32(Int32.max)+1).octype)
        print("Int64:",NSNumber(value: Int64.max).octype)
        print("UInt64:",NSNumber(value: UInt64(Int64.max)+1).octype)
        print("Int:",NSNumber(value: Int.max).octype)
        print("UInt:",NSNumber(value: UInt(Int.max)+1).octype)
        print(JSON(Int64.max).intValue)
        print(JSON(Int64.min).intValue)
        print(JSON(UInt64(Int64.max)+1).intValue) // overflow
        print(JSON(UInt64(Int64.max)+2).intValue) // overflow
        print(JSON(UInt64(Int64.max)+3).intValue) // overflow
    }
    func testCollection() throws {
        var json = JSON("hello world")
        print(json[.none])
        print(json[0])
        let set:Set<String> = ["a","b","c"]
        print("set:",JSON(set))
        XCTAssertTrue(json.isEmpty) //Single value is an Empty Collection
        XCTAssertTrue(json.count==0,"Single Json Collection Error")
        json = JSON(["a","b",1,true,1.231231321])
        for (key,value) in json{
            print(key,":",value)
        }
        XCTAssertTrue(json.count==5,"Array Json Collection Error")
        json = JSON(["name":"jack","age":10,"gender":1,"isok":true])
        for (key,value) in json{
            print(key,":",value)
        }
        XCTAssertTrue(json.count==4,"Object Json Collection Error")
    }
    func testSubscript() throws{
        // With subscript in array
        var json: JSON =  [1,2,3]
        json[0] = 100
        json[1] = 200
        json.2 = 300 //dynamicMemberLookup
        json[9] = 999 // Don't worry, nothing will happen just a warning info
        json.10 = 9999 //out of bounds
        json.name = "Tome" // JSON.Array not support string subscirpt. nothing happend
        XCTAssertEqual(json[0].int, 100)
        XCTAssertEqual(json.1.int, 200)//dynamicMemberLookup
        XCTAssertEqual(json[2].int, 300)//dynamicMemberLookup
        XCTAssertEqual(json.name, .null)
        XCTAssertEqual(json[9], .null)
        // With subscript in Object
        json =  ["name": "Jack", "age": 25]
        json["name"] = "Mike"
        json["age"] = "25" // It's OK to set String
        json["address"] = "Newyork" // Add the "address": "Newyork" in json
        XCTAssertEqual(json, ["name": "Mike", "age": "25","address":"Newyork"])
        // Array & Object
        var dic:JSON = ["name": "Jack", "age": 25, "list": ["a", "b", "c"]]
        dic["list"][2] = "that"
        XCTAssertEqual(dic.list[2].string, "that")
        XCTAssertEqual(dic["list",2].string, "that")
        XCTAssertEqual(dic.list.2.string, "that")
        // With other JSON objects
        let user: JSON = ["username" : "Steve", "password": "supersecurepassword"]
        let auth: JSON = [
          "user": user, // use user.object instead of just user
          "apikey": "supersecretapitoken"
        ]
        XCTAssertEqual(auth.user, user)
        
        var obj = JSON(["key":"value"])
        XCTAssertEqual(obj.key.string, "value")
        obj.key = .null // set JSON.null for key
        XCTAssertNil(obj.key.string)
        XCTAssertEqual(obj.count, 1)
        
        obj.key = "other"
        XCTAssertEqual(obj.key.string, "other")
        obj.key = nil // set JSON.null for key
        XCTAssertNil(obj.key.string)
        XCTAssertEqual(obj.count, 1)
        obj.delete(key:"key") // will remove the key
        XCTAssertEqual(obj.count, 0)
        XCTAssertNil(obj.key.string)
    }
    func testGetters() throws {
        var json = JSON(parse:"{\"float\":1.844674407370955e+30}")
        json["int"] = 1 // save as JSON.number(1)
        json["int8"] = JSON(Int8(1)) // save as JSON.bool(true)
        json["false"] = JSON(false)
        json["strFalse"] = "false"
        json["strTrue"] = "true"
        json["int16"] = JSON(Int16.max)
        json["int32"] = JSON(Int32.max)
        json["int_min"] = JSON(Int64.min)
        json["int_max"] = JSON(Int64.max)
        json["uint_max"] = JSON(UInt64.max)
        json["ary"] = [true,Double.pi,Int64.min,Int64.max,UInt64.max]
        json["dic"] = ["name":"jackson","age":18,"obj":json]
        json["empty"] = [:]
        json["null"] = .null
        json.test = "test"
        
        XCTAssertEqual(json["int"].int8, 1) // Int(1) != true
        XCTAssertEqual(json["int"].bool, nil)
        XCTAssertEqual(json.int, nil)  // It can only be reduced to subscipt, When dynamicMemberLookup has a confrontation with getters
        XCTAssertEqual(json["int8"].int8, 1) // Int8(1) == true
        XCTAssertEqual(json["int8"].bool, true)
        XCTAssertEqual(json["int8"].string, "true") // true -> "true"
        XCTAssertEqual(json["false"].int8, 0)
        XCTAssertEqual(json.false.int8, 0)
        XCTAssertEqual(json["false"].bool, false)
        XCTAssertEqual(json["false"].string, "false")// false -> "false"
        
        XCTAssertEqual(json["strFalse"].bool, false) // "false" -> false
        XCTAssertEqual(json["strFalse"].number, nil)
        XCTAssertEqual(json["strTrue"].bool, true)// "true" -> true
        XCTAssertEqual(json["strTrue"].number, nil)
        XCTAssertEqual(json["test"].bool, nil)
        XCTAssertEqual(json["test"].number, nil)
        
        XCTAssertEqual(json["int16"].int16, Int16.max)
        XCTAssertNil(json["int16"].bool)
        XCTAssertEqual(json["int32"].int32, Int32.max)
        XCTAssertEqual(json["null"].int16, nil)
        XCTAssertEqual(json["uint_max"].uint64, UInt64.max)
        XCTAssertEqual(json["uint_max"].uint64Value, UInt64.max)
        XCTAssertEqual(json["ary"].array?.count, 5)
        XCTAssertEqual(json["ary"].arrayValue.count, 5)
        XCTAssertEqual(json.ary.0.bool, true)// dynamicMemberLookup also works for arrays
        XCTAssertEqual(json["dic"].object?.count, 3)
        XCTAssertEqual(json["dic"].objectValue.count, 3)
        XCTAssertEqual(json.objectValue.count, json.count)
    }
    func testRawValue() throws {
        let bool:Bool? = true
        let int:Int? = nil
        var json:JSON = (try? JSON.parse("{\"float\":1.844674407370955e+30}")) ?? .null
        json["int16"] = JSON(Int16.max)
        json["int32"] = JSON(Int32.max)
        json["int_min"] = JSON(Int64.min)
        json["int_max"] = JSON(Int64.max)
        json["uint_max"] = JSON(UInt64.max)
        json["ary"] = [true,Double.pi,Int64.min,Int64.max,UInt64.max,int,[bool],[int,2]]
        json["dic"] = ["name":"jackson","age":18,"obj":json,"int":int]
        json["empty"] = [:]
        json["null"] = .null
        json.test = "test"
        XCTAssertEqual(json, JSON(json.rawValue))
        XCTAssertEqual(json, JSON(parse: json.rawData!))
    }
    func testCodable() throws {
        var json:JSON = [:] //ExpressibleByDictionaryLiteral
        json["int16"] = JSON(Int16.max)
        json["int32"] = JSON(Int32.max)
        json["int_min"] = JSON(Int64.min)
        json["int_max"] = JSON(Int64.max)
        json["uint_max"] = JSON(UInt64.max)
        json["float"] = 1.844674407370955e+30
        json.str = "ExpressibleByStringInterpolation\(1)" // ExpressibleByStringInterpolation,dynamicMemberLookup
        json["bool"] = true //ExpressibleByBooleanLiteral
        json["int"] = 3123123123//ExpressibleByIntegerLiteral
        json["ary"] = [true,1.1,Double.pi,Int64.min,Int64.max,UInt64.max,11,[false]]//ExpressibleByArrayLiteral
        json["dic"] = ["name":"jackson","age":18,"obj":["key":"value"],"int":9999999]//ExpressibleByDictionaryLiteral
        json.null = .object(["null":.null])
        json.int_max.test = 10 // warning happend
        json.ary[10] = 1 // nothing happend
        XCTAssertEqual(json.dic.count, 4)
        XCTAssertEqual(json.ary[10], .null) // Got null rather than crash
        XCTAssertEqual(json.ary.count, 8)
        json["ary"] = nil // ExpressibleByNilLiteral
        XCTAssertEqual(json.ary, .null) // got null
        XCTAssertEqual(json.ary.count, 0)
        XCTAssertEqual(json.noexist, .null) // got null
        XCTAssertEqual(json.test.notexist, .null)
        let ajson = try! JSONDecoder().decode(JSON.self, from: try! JSONEncoder().encode(json))//encode and decode
        let bjson = try! JSON.parse(try! JSONEncoder().encode(json))//encode and decode
        let cjson = try! JSONDecoder().decode(JSON.self, from: json.rawData!)//encode and decode
        let djson = try! JSON.parse(json.rawData!)//encode and decode
        XCTAssertEqual(ajson, json)
        XCTAssertEqual(bjson, json)
        XCTAssertEqual(cjson, json)
        XCTAssertEqual(djson, json)
    }
    func testMerge() throws{
        var base: JSON = [
            "firstName": "Michael",
            "age": 30,
            "skills": ["Coding", "Reading"],
            "address": [
                "street": "Front St",
                "zip": "12345",
            ]
        ]

        let update: JSON = [
            "lastName": "Jackson",
            "age": 32,
            "skills": ["Singing","Dancing"],
            "address": [
                "zip": "12342",
                "city": "New York City",
                "post": "123213"
            ]
        ]
        let expect = """
            {
              "address" : {
                "city" : "New York City",
                "post" : "123213",
                "street" : "Front St",
                "zip" : "12342"
              },
              "age" : 32,
              "firstName" : "Michael",
              "lastName" : "Jackson",
              "skills" : [
                "Coding",
                "Reading",
                "Singing",
                "Dancing"
              ]
            }
        """
        let newone = base.merged(from: update)
        base.merge(from:update)
        XCTAssertEqual(base,newone)
        XCTAssertEqual(base,JSON(parse: expect))
    }
}
