//
//  JSONParsePerformanceTests.swift
//  JSONParsePerformanceTests
//
//  Created by GorXion on 2018/5/3.
//  Copyright © 2018年 Ginxx. All rights reserved.
//

import XCTest
@testable import JSONParsePerformance
import HandyJSON
import CleanJSON

struct Airport: Codable {
    let name: String
    let iata: String
    let icao: String
    let coordinates: [Double]
    
    struct Runway: Codable {
        let direction: String
        let distance: Int
    }
    
    let runways: [Runway]
}

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
        self.runways = runways.map { Runway(json: $0) }
    }
}

extension Airport.Runway {
    public init(json: [String: Any]) {
        guard let direction = json["direction"] as? String,
            let distance = json["distance"] as? Int
            else {
                fatalError("Cannot initialize Runway from JSON")
        }
        
        self.direction = direction
        self.distance = distance
    }
}

struct Handy: HandyJSON {
    
    var name: String?
    var iata: String?
    var icao: String?
    var coordinates: [Double]?
    var runways: [Runway]?
    
    struct Runway: HandyJSON {
        var direction: String?
        var distance: Int?
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

let data = airportsJSON(count: 1000) // or 1, 10, 100, 1000, 10000

class JSONParsePerformanceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHandyJSON() {
        let json = String(data: data, encoding: .utf8)
        measure {
            _ = JSONDeserializer<Handy>.deserializeModelArrayFrom(json: json)
        }
    }
    
    func testCleanJSON() {
        measure {
            let decoder = CleanJSONDecoder()
            _ = try! decoder.decode([Airport].self, from: data)
        }
    }
    
    func testJSONSerialization() {
        measure {
            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
            _ = json.map{ Airport(json: $0) }
        }
    }
}
