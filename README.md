# swift-json

![Platform](https://img.shields.io/badge/platforms-iOS%208.0%20%7C%20macOS%2010.10%20%7C%20tvOS%209.0%20%7C%20watchOS%203.0-F28D00.svg)

swift-json makes it easy to deal with JSON data in Swift.


1. [Why](#why)
2. [Requirements](#requirements)
3. [Integration](#integration)
4. [Usage](#usage)
   - [Initialization](#initialization)
   - [Collection](#collection)
   - [Getter](#getters)
   - [Raw Values](#raw-values)
   - [Literal convertibles](#literal-convertibles)
   - [Subscript](#subscript)   
   - [Merging](#merging)
5. [Work with Alamofire](#work-with-alamofire)
6. [Work with Moya](#work-with-moya)

## Why
To be fast, light, and elegant, `swift-json` is based on `swift enum` and provides many utility features

`swift-json` is not only a traditional json data structure. It's a generic data structure. So in many cases you can use `JSON` instead of `Any`

Swift is very strict about types. But although explicit typing is good for saving us from mistakes, it becomes painful when dealing with JSON and other areas that are, by nature, implicit about types.

The code would look like this:

```swift
if let statusesArray = try? JSONSerialization.jsonObject(with: dataFromNetworking, options: .allowFragments) as? [[String: Any]],
    let user = statusesArray[0]["user"] as? [String: Any],
    let username = user["name"] as? String {
    // Finally we got the username
}
```

It's not good.

Even if we use optional chaining, it would be messy:

```swift
if let object = try JSONSerialization.jsonObject(with: dataFromNetworking, options: .allowFragments) as? [[String: Any]],
    let username = (object[0]["user"] as? [String: Any])?["name"] as? String {
        // There's our username
}
```

An unreadable mess--for something that should really be simple!

With `swift-json` all you have to do is:

```swift
let json = JSON(parse: dataFromNetworking)
if let name = json[0]["user"]["name"].string {
  //Now you got your value
}
if let name = json[0,"user","name"].string {
  //Now you got your value
}
```

## Requirements

- iOS 8.0+ | macOS 10.10+ | tvOS 9.0+ | watchOS 2.0+
- Xcode 8

## Integration

#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `swift-json` by adding the proper description to your `Package.swift` file:

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/sutext/swift-json.git", from: "1.0.0"),
    ]
)
```
Then run `swift build` whenever you get prepared.

## Usage

#### Initialization

```swift
import JSON
```

```swift
    func testUsage() throws{
        let jsonString = "{\"b0\":0,\"b1\":true,\"b2\":125,\"b3\":\"true\",\"b4\":1}"
        let json = JSON(parse: jsonString)
        XCTAssertEqual(json.rawString, jsonString) // parse rawString
        
        let decodeJson = try? JSON.parse(json.rawData!) // parse rawData
        XCTAssertEqual(json, decodeJson)
        XCTAssertEqual(decodeJson?.rawString, jsonString)
        
        let rawJson = JSON(json.rawValue) // init rawValue
        XCTAssertEqual(json, rawJson)
    }
```

#### Collection

```swift
    func testCollection() throws {
        var json = JSON("hello world")
        print(json[.none])
        print(json[0])
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
```

####  Getters

```swift
    func testGetters() throws {
        var json = JSON(parse:"{\"float\":1.844674407370955e+30}")
        json["zero"] = 0
        json["int"] = 1
        json["false"] = JSON(false)
        json["strFalse"] = "false"
        json["strTrue"] = "true"
        json["int8"] = JSON(Int8.max) //
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
        XCTAssertEqual(json["zero"].int, 0)
        XCTAssertEqual(json["zero"].bool, false)
        XCTAssertEqual(json["int"].int8, 1)
        XCTAssertEqual(json["int"].bool, true)
        XCTAssertEqual(json.int, nil)  // It can only access with subscript, when dynamicMemberLookup has a confrontation with getters
        XCTAssertEqual(json["int8"].int8, 127)
        XCTAssertEqual(json["int8"].bool, true)
        XCTAssertEqual(json["false"].int8, 0)
        XCTAssertEqual(json.false.int8, 0)
        XCTAssertEqual(json["false"].bool, false)
        XCTAssertEqual(json["false"].string, "false")
        
        XCTAssertEqual(json["strFalse"].bool, false)
        XCTAssertEqual(json["strFalse"].number, nil)
        XCTAssertEqual(json["strTrue"].bool, true)
        XCTAssertEqual(json["strTrue"].number, nil)
        XCTAssertEqual(json["test"].bool, nil)
        XCTAssertEqual(json["test"].number, nil)
        
        XCTAssertEqual(json["int16"].int16, Int16.max)
        XCTAssertEqual(json["int16"].bool,true)
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
```

#### Raw Values

```swift
    func testRawValue() throws {
        let bool:Bool? = true
        let int:Int? = nil
        var json:JSON = (try? JSON.parse("{\"float\":1.844674407370955e+30}")) ?? .null
        json["int16"] = JSON(Int16.max)
        json["int32"] = JSON(Int32.max)
        json["int_min"] = JSON(Int64.min)
        json["int_max"] = JSON(Int64.max)
        json["uint_max"] = JSON(UInt64.max)
        json["ary"] = [true,Double.pi,Int64.min,Int64.max,UInt64.max,int,[bool],[int]]
        json["dic"] = ["name":"jackson","age":18,"obj":json,"int":int]
        json["empty"] = [:]
        json["null"] = .null
        json.test = "test"
        let rawValue = json.rawValue
        XCTAssertEqual(json, JSON(rawValue))
        let rowData = json.rawData!
        XCTAssertEqual(json, JSON(parse: rowData))
    }
```


#### Literal convertibles

For more info about literal convertibles: [Swift Literal Convertibles](http://nshipster.com/swift-literal-convertible/)

```swift
    func testCodable() throws {
        var json:JSON = [:] //ExpressibleByDictionaryLiteral
        json["int16"] = JSON(Int16.max)
        json["int32"] = JSON(Int32.max)
        json["int_min"] = JSON(Int64.min)
        json["int_max"] = JSON(Int64.max)
        json["uint_max"] = JSON(UInt64.max)
        json["float"] = 1.844674407370955e+30
        json.str = "ExpressibleByStringInterpolation" // ExpressibleByStringInterpolation,dynamicMemberLookup
        json["bool"] = true //ExpressibleByBooleanLiteral
        json["int"] = 3123123123//ExpressibleByIntegerLiteral
        json["ary"] = [true,Double.pi,Int64.min,Int64.max,UInt64.max,11,[false]]//ExpressibleByArrayLiteral
        json["dic"] = ["name":"jackson","age":18,"obj":["key":"value"],"int":9999999]//ExpressibleByDictionaryLiteral
        json.int_max.test = 10 // warning happend
        json.ary[10] = 1 // nothing happend
        XCTAssertEqual(json.dic.count, 4)
        XCTAssertEqual(json.ary[10], .null) // Got null rather than crash
        XCTAssertEqual(json.ary.count, 7)
        json["ary"] = nil // same as json["ary"] = .null; Means delete ary key
        XCTAssertEqual(json.ary, .null) // got null
        XCTAssertEqual(json.ary.count, 0)
        XCTAssertEqual(json.noexist, .null) // got null
        XCTAssertEqual(json.test.notexist, .null)
        let ajson = try! JSON.parse(json.rawString!)//encode and decode
        XCTAssertEqual(ajson, json)
    }
```

#### Subscript

```swift
    func testSubscript() throws{
        // With subscript in array
        var json: JSON =  [1,2,3]
        json[0] = 100
        json[1] = 200
        json[2] = 300
        json[99] = 999 // Don't worry, nothing will happen just a warning info
        XCTAssertEqual(json[0].int, 100)
        XCTAssertEqual(json[99], .null)
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
        // With other JSON objects
        let user: JSON = ["username" : "Steve", "password": "supersecurepassword"]
        let auth: JSON = [
          "user": user, // use user.object instead of just user
          "apikey": "supersecretapitoken"
        ]
        XCTAssertEqual(auth.user, user)
    }
```

#### Merging

It is possible to merge one JSON into another JSON. Merging a JSON into another JSON adds all non existing values to the original JSON which are only present in the `other` JSON.

If both JSONs contain a value for the same key, _mostly_ this value gets overwritten in the original JSON, but there are two cases where it provides some special treatment:

- In case of both values being a `JSON.Array` the values form the array found in the `other` JSON getting appended to the original JSON's array value.
- In case of both values being a `JSON.Object` both JSON-values are getting merged the same way the encapsulating JSON is merged.

In a case where two fields in a JSON have different types, the value will get always overwritten.

There are two different fashions for merging: `merge` modifies the original JSON, whereas `merged` works non-destructively on a copy.

```swift
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
```


## Work with [Alamofire](https://github.com/Alamofire/Alamofire)

swift-json nicely wraps the result of the Alamofire JSON response handler:

```swift
Alamofire.request(url, method: .get).validate().responseJSON { resp in
    switch resp.result {
    case .success(let value):
        let json = JSON(value)
        print("JSON: \(json)")
    case .failure(let error):
        print(error)
    }
}
```

## Work with [Moya](https://github.com/Moya/Moya)

swift-json parse data to JSON:

```swift
let provider = MoyaProvider<Backend>()
provider.request(.getUserInfo) { result in
    switch result {
    case let .success(resp):
        let json = JSON(parse: resp.data) // convert network data to json
        print(json)
    case let .failure(error):
        print("error: \(error)")
    }
}

```
