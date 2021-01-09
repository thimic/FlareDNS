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


struct DNSContent: Codable, RawRepresentable, ExpressibleByArgument {
    var rawValue: String
}


struct Zone: Codable, Equatable, Hashable {
    
    let name: String
    var id: String? = nil
}


struct ZoneListResponse: Codable, Equatable {
    let success: Bool
    let errors: [String]
    let messages: [String]
    let result: [Zone]
}


enum DNSRecordTypes: String, Codable, CaseIterable, ExpressibleByArgument {
    case A, AAAA, CNAME, MX, TXT
}


struct DNSRecord: Codable, Equatable {
    
    init(zone: Zone, name: String, type: DNSRecordTypes = .A, ttl: Int = 1, priority: Int = 0, proxied: Bool = true) {
        self.zone = zone
        self.name = name
        self.type = type
        self.ttl = ttl
        self.priority = priority
        self.proxied = proxied
    }
    
    init(zoneName: String, recordName: String, type: DNSRecordTypes = .A, ttl: Int = 1, priority: Int = 0, proxied: Bool = true) {
        self.zone = Zone(name: zoneName)
        self.name = recordName
        self.type = type
        self.ttl = ttl
        self.priority = priority
        self.proxied = proxied
    }
    
    var zone: Zone
    var id: String? = nil
    let name: String
    var type: DNSRecordTypes = .A
    var ttl: Int = 1  // 1 = automatic
    var priority: Int = 0
    var proxied: Bool = true
    
    func createRequest(ip: DNSContent) -> DNSRecordRequest {
        DNSRecordRequest(type: type, name: name, content: ip, ttl: ttl, proxied: proxied)
    }

}


struct DNSRecordRequest: Codable {
    
    var type: DNSRecordTypes
    let name: String
    var content: DNSContent
    var ttl: Int = 1800
    let proxied: Bool
}


struct DNSRecordResponse: Codable, Equatable {
    
    let id: String
    let type: DNSRecordTypes
    let name: String
    let content: String
    let proxiable: Bool
    let proxied: Bool
    let ttl: Int
    let locked: Bool
    let zoneID: String
    let zoneName: String
    let modifiedOn: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case content
        case proxiable
        case proxied
        case ttl
        case locked
        case zoneID = "zone_id"
        case zoneName = "zone_name"
        case modifiedOn = "modified_on"
    }

}
