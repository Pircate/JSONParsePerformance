//
//  JSONParsePerformanceTests.swift
//  JSONParsePerformanceTests
//
//  Created by GorXion on 2018/5/3.
//  Copyright © 2018年 Ginxx. All rights reserved.
//

import XCTest
@testable import JSONParsePerformance
import ObjectMapper
import HandyJSON
import CleanJSON

// CleanJSON
struct Airport: Codable {
    let name: String
    let iata: String
    let icao: String
    let coordinates: [Double]
    
    struct Runway: Codable {
        enum Surface: String, Codable {
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        let direction: String
        let distance: Int
        let surface: Surface
    }
    
    let runways: [Runway]
}

// JSONSerialization
extension Airport {
    public init(json: [String: Any]) {
        guard let name = json["name"] as? String,
            let iata = json["iata"] as? String,
            let icao = json["icao"] as? String,
            let coordinates = json["coordinates"] as? [Double],
            let runways = json["runways"] as? [[String: Any]]
            else {
                fatalError("Cannot initialize Airport from JSON")
        }
        
        self.name = name
        self.iata = iata
        self.icao = icao
        self.coordinates = coordinates
        self.runways = runways.map(Runway.init)
    }
}

extension Airport.Runway {
    public init(json: [String: Any]) {
        guard let direction = json["direction"] as? String,
            let distance = json["distance"] as? Int,
            let surfaceRawValue = json["surface"] as? String,
            let surface = Surface(rawValue: surfaceRawValue)
            else {
                fatalError("Cannot initialize Runway from JSON")
        }
        
        self.direction = direction
        self.distance = distance
        self.surface = surface
    }
}

// HandyJSON
struct Handy: HandyJSON {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
    var runways: [Runway]?
    
    struct Runway: HandyJSON {
        enum Surface: String, HandyJSONEnum {
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        var direction: String?
        var distance: Int?
        var surface: Surface?
    }
}

// ObjectMapper
struct Object: ImmutableMappable {
    
    var name: String
    var iata: String
    var icao: String
    var coordinates: [Double]
    var runways: [Runway]
    
    init(map: Map) throws {
        name = try map.value("name")
        iata = try map.value("iata")
        icao = try map.value("icao")
        coordinates = try map.value("coordinates")
        runways = try map.value("runways")
    }
    
    mutating func mapping(map: Map) {
        name <- map["name"]
        iata <- map["iata"]
        icao <- map["icao"]
        coordinates <- map["coordinates"]
        runways <- map["runways"]
    }
    
    struct Runway: ImmutableMappable {
        enum Surface: String {
            case rigid, flexible, gravel, sealed, unpaved, other
        }
        
        var direction: String
        var distance: Int
        var surface: Surface
        
        init(map: Map) throws {
            direction = try map.value("direction")
            distance = try map.value("distance")
            surface = try map.value("surface")
        }
        
        mutating func mapping(map: Map) {
            direction <- map["direction"]
            distance <- map["distance"]
            surface <- map["surface"]
        }
    }
}

func airportsJSON(count: Int) -> Data {
    let resource = "airports\(count)"
    guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
        let data = try? Data(contentsOf: url) else {
            fatalError()
    }
    return data
}

let count = 1000 // or 1, 10, 100, 1000, 10000
let data = airportsJSON(count: count)

class JSONParsePerformanceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObjectMapper() {
        measure {
            let json = String(data: data, encoding: .utf8)!
            do {
                let objects = try Mapper<Object>().mapArray(JSONString: json)
                XCTAssertEqual(objects.count, count)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    
    func testHandyJSON() {
        measure {
            let json = String(data: data, encoding: .utf8)
            let objects = JSONDeserializer<Handy>.deserializeModelArrayFrom(json: json)
            XCTAssertEqual(objects?.count, count)
        }
    }
    
    func testCleanJSON() {
        measure {
            let decoder = CleanJSONDecoder()
            do {
                let objects = try decoder.decode([Airport].self, from: data)
                XCTAssertEqual(objects.count, count)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
    
    func testJSONSerialization() {
        measure {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
                let objects = json.map(Airport.init)
                XCTAssertEqual(objects.count, count)
            } catch {
                XCTAssertNil(error)
            }
        }
    }
}
