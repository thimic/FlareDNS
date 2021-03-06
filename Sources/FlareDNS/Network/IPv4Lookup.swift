//
//  File.swift
//  
//
//  Created by Michael Thingnes on 15/12/20.
//

import Foundation
import Logging
import PromiseKit


struct IPv4LookupAPI {
    
    static let shared = IPv4LookupAPI()
    
    private let requestManager = RequestManager()
    
    private func getIpFromLookup(_ lookup: Lookups) -> Promise<DNSContent> {
        return Promise { seal in
            requestManager.get(from: lookup.value.endpoint)
                .done { data in
                    guard let ip = lookup.value.decode(data) else {
                        seal.reject(FlareDNSError("Unable to opdatin IP address using \(lookup.value.endpoint.path)"))
                        return
                    }
                    seal.fulfill(ip)
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    func getIP() -> Promise<DNSContent> {
        var attempts = 0
        func attempt() -> Promise<DNSContent> {
            let lookup = Lookups.allCases[attempts]
            attempts += 1
            return getIpFromLookup(lookup).recover { error -> Promise<DNSContent> in
                Logger.shared.warning("Unable to look up IP using \(lookup.value.endpoint)")
                guard attempts < Lookups.allCases.count else { throw error }
                return attempt()
            }
        }
        return attempt()
    }
    
}

extension IPv4LookupAPI {

    enum Lookups: CaseIterable {

        case googleWifi, amazonAWS, ipEcho, ipInfo, ipIfy
        
        struct IPv4Lookup {
            typealias IPv4DataDecoder = (Data) -> DNSContent?
            
            let endpoint: URL
            let decode: IPv4DataDecoder
        }
        
        var value: IPv4Lookup {
            switch self {
            case .googleWifi:
                return IPv4Lookup(endpoint: URL(string: "http://onhub.here/api/v1/status")!) { data in
                    
                    struct Wan: Codable {
                        let localIpAddress: DNSContent
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
                    return DNSContent(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .ipEcho:
                return IPv4Lookup(endpoint: URL(string: "http://ipecho.net/plain")!) { data in
                    guard let string = String(data: data, encoding: .utf8) else { return nil }
                    return DNSContent(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .ipInfo:
                return IPv4Lookup(endpoint: URL(string: "http://ipinfo.io/ip")!) { data in
                    guard let string = String(data: data, encoding: .utf8) else { return nil }
                    return DNSContent(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case .ipIfy:
                return IPv4Lookup(endpoint: URL(string: "https://api.ipify.org")!) { data in
                    guard let string = String(data: data, encoding: .utf8) else { return nil }
                    return DNSContent(rawValue: string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }

}
