//
//  IPv4LookupUnifi.swift
//  
//
//  Created by Michael Thingnes on 11/12/22.
//

import Foundation


struct IPv4LookupUnifi: IPv4Lookupable {

    private static let host = ProcessInfo.processInfo.environment["FLAREDNS_UNIFI_HOST"] ?? "unifi"
    private static let port = ProcessInfo.processInfo.environment["FLAREDNS_UNIFI_PORT"] ?? "8443"
    private static let username = ProcessInfo.processInfo.environment["FLAREDNS_UNIFI_USERNAME"] ?? ""
    private static let password = ProcessInfo.processInfo.environment["FLAREDNS_UNIFI_PASSWORD"] ?? ""
    private static let allowSelfSigned = Bool(
        argument: ProcessInfo.processInfo.environment["FLAREDNS_UNIFI_ALLOW_SELF_SIGNED_CERT"] ?? "false"
    ) ?? false

    let name = "Unifi Controller"
    let sessionType: SessionType = Self.allowSelfSigned ? .insecure : .standard
    let endpoint = URL(string: "https://\(Self.host):\(Self.port)/api/s/default/stat/health")!
    let login: Login? = Login(
        method: .post,
        url: URL(string: "https://\(Self.host):\(Self.port)/api/login")!,
        headers: ["Content-Type": "application/json"],
        body: ["username": Self.username, "password": Self.password]
    )

    var dataHandler: DNSHandler = { data in
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(UnifiHealth.self, from: data)
            .data
            .compactMap(\.wanIp)
            .first
    }

}

private extension IPv4LookupUnifi {

    struct HealthData: Decodable {
        let wanIp: DNSContent?
    }

    struct UnifiHealth: Decodable {
        let data: [HealthData]
    }

}
