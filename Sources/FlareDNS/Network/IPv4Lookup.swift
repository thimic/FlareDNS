//
//  IPv4Lookup.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation
import Logging


enum IPv4Lookup: CaseIterable {

    case unifi
    case googleWifi
    case amazonAWS
    case ipEcho
    case ipInfo
    case ipIfy

}

extension IPv4Lookup {

    var name: String { lookupInfo.name }
    var endpoint: URL { lookupInfo.endpoint }

    func getIP(requestManager: RequestManager) async throws -> DNSContent {
        if let login = lookupInfo.login {
            let body = try? JSONEncoder().encode(login.body)
            try await requestManager.request(
                from: login.url,
                method: login.method,
                headers: login.headers,
                body: body,
                certificateVerification: lookupInfo.certificateVerification
            )
        }
        let data = try await requestManager.get(from: lookupInfo.endpoint, certificateVerification: lookupInfo.certificateVerification)
        guard let ip = lookupInfo.dataHandler(data) else {
            throw FlareDNSError.lookupFailed(endpoint: lookupInfo.endpoint)
        }
        Logger.shared.warning("Found IP using \(lookupInfo.endpoint): \(ip.rawValue)")
        return ip
    }

}

private extension IPv4Lookup {

    var lookupInfo: any IPv4Lookupable {
        switch self {
        case .unifi:
            return IPv4LookupUnifi()
        case .googleWifi:
            return IPv4LookupGoogleWifi()
        case .amazonAWS:
            return IPv4LookupAWS()
        case .ipEcho:
            return IPv4LookupIPEcho()
        case .ipInfo:
            return IPv4LookupIPInfo()
        case .ipIfy:
            return IPv4LookupIPify()
        }
    }

}
