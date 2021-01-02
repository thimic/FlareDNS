//
//  File.swift
//  
//
//  Created by Michael Thingnes on 15/12/20.
//

import Foundation
import ArgumentParser


enum IPv4Lookups: CaseIterable {

    case googleWifi, amazonAWS, ipEcho, ipInfo, ipIfy
    
    var value: IPv4Lookup {
        switch self {
        case .googleWifi:
            return IPv4Lookup(endpoint: URL(string: "http://onhub.here/api/v1/status")!) { data in
                
                struct Wan: Codable {
                    let localIpAddress: IPAddress
                }
                
                struct GoogleWifi: Codable {
                    let wan: Wan
                }
                
                let decoder = JSONDecoder()
                guard let jsonData = try? decoder.decode(GoogleWifi.self, from: data) else { return nil }
                return jsonData.wan.localIpAddress
            }
        case .amazonAWS:
            return IPv4Lookup(endpoint: URL(string: "https://checkip.amazonaws.com")!) { data in
                guard let string = String(data: data, encoding: .utf8) else { return nil }
                return IPAddress(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        case .ipEcho:
            return IPv4Lookup(endpoint: URL(string: "http://ipecho.net/plain")!) { data in
                guard let string = String(data: data, encoding: .utf8) else { return nil }
                return IPAddress(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        case .ipInfo:
            return IPv4Lookup(endpoint: URL(string: "http://ipinfo.io/ip")!) { data in
                guard let string = String(data: data, encoding: .utf8) else { return nil }
                return IPAddress(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        case .ipIfy:
            return IPv4Lookup(endpoint: URL(string: "https://api.ipify.org")!) { data in
                guard let string = String(data: data, encoding: .utf8) else { return nil }
                return IPAddress(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
}
