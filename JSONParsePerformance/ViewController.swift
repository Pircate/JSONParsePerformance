//
//  ViewController.swift
//  JSONParsePerformance
//
//  Created by GorXion on 2018/5/3.
//  Copyright © 2018年 Ginxx. All rights reserved.
//

import UIKit
import HandyJSON

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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let data = airportsJSON(count: 10000) // 1, 10, 100, 1000, or 10000
        
        let date0 = Date().timeIntervalSince1970
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        _ = json.map{ Airport(json: $0) }
        debugPrint("JSONSerialization:", Date().timeIntervalSince1970 - date0)
        
        let date1 = Date().timeIntervalSince1970
        let decoder = JSONDecoder()
        _ = try! decoder.decode([Airport].self, from: data)
        debugPrint("JSONDecoder:", Date().timeIntervalSince1970 - date1)
        
        let date2 = Date().timeIntervalSince1970
        _ = JSONDeserializer<Handy>.deserializeModelArrayFrom(json: String(data: data, encoding: .utf8))
        debugPrint("HandyJSON:", Date().timeIntervalSince1970 - date2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func airportsJSON(count: Int) -> Data {
        let resource = "airports\(count)"
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
                fatalError()
        }
        return data
    }
}

