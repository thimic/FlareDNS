//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import ArgumentParser


struct ApiToken: Codable, RawRepresentable {
    var rawValue: String
}


struct IPAddress: Codable, RawRepresentable, ExpressibleByArgument {
    var rawValue: String
}


struct IPv4Lookup {
    typealias IPv4DataDecoder = (Data) -> IPAddress?
    
    let endpoint: URL
    let decode: IPv4DataDecoder
}


struct Zone: Codable, Equatable {
    
    let name: String
    var id: String? = nil
}


struct ZoneListResponse: Codable, Equatable {
    let success: Bool
    let errors: [String]
    let messages: [String]
    let result: [Zone]
}


struct DNSRecord: Codable, Equatable {
    
    init(zone: Zone, name: String, type: Types = .A, ttl: Int = 1, priority: Int = 0, proxied: Bool = true) {
        self.zone = zone
        self.name = name
        self.type = type
        self.ttl = ttl
        self.priority = priority
        self.proxied = proxied
    }
    
    init(zoneName: String, recordName: String, type: Types = .A, ttl: Int = 1, priority: Int = 0, proxied: Bool = true) {
        self.zone = Zone(name: zoneName)
        self.name = recordName
        self.type = type
        self.ttl = ttl
        self.priority = priority
        self.proxied = proxied
    }
    
    enum Types: String, Codable, CaseIterable, ExpressibleByArgument {
        case A, AAAA, CNAME
    }
    
    var zone: Zone
    let name: String
    var type: Types = .A
    var ttl: Int = 1  // 1 = automatic
    var priority: Int = 0
    var proxied: Bool = true

}


struct DNSRecordResponse: Codable, Equatable {
    
    enum Types: String, Codable, CaseIterable, ExpressibleByArgument {
        case A, AAAA, CNAME
    }
    
    let id: String
    let type: Types
    let name: String
    let content: String
    let proxiable: Bool
    let proxied: Bool
    let ttl: Int
    let locked: Bool
    let zoneID: String
    let zoneName: String
    let modifiedOn: String

}
