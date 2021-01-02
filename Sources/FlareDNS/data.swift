//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import ArgumentParser


struct AccessToken: Codable, RawRepresentable {
    var rawValue: String
}


struct Zone: Codable, Equatable {
    
    let id: String
    let name: String
    
}


struct DNSRecord: Codable, Equatable {
    
    enum Types: String, Codable, CaseIterable, ExpressibleByArgument {
        case A, AAAA, CNAME
    }
    
    let name: String
    var type: Types = .A
    var ttl: Int = 1  // 1 = automatic
    var priority: Int = 0
    var proxied: Bool = true

}
