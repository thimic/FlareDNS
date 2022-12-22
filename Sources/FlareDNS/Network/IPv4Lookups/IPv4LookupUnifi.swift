//
//  IPv4LookupUnifi.swift
//  
//
//  Created by Michael Thingnes on 11/12/22.
//

import Foundation
import NIOSSL


struct IPv4LookupUnifi: IPv4Lookupable {

    let name = "Unifi Controller"
    var certificateVerification: CertificateVerification {
        allowSelfSigned ? .none : .fullVerification
    }
    // TODO: Force unwrapping here is really not safe
    var endpoint: URL { URL(string: "https://\(host):\(port)/api/s/default/stat/health")! }
    var login: Login? {
        Login(
            method: .POST,
            url: URL(string: "https://\(host):\(port)/api/login")!,
            headers: ["Content-Type": "application/json"],
            body: ["username": username, "password": password]
        )
    }

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

    var host: String { environment("FLAREDNS_UNIFI_HOST", default: "unifi") }
    var port: String { environment("FLAREDNS_UNIFI_PORT", default: "8443") }
    var username: String { environment("FLAREDNS_UNIFI_USERNAME") }
    var password: String { environment("FLAREDNS_UNIFI_PASSWORD") }
    var allowSelfSigned: Bool { environment("FLAREDNS_UNIFI_ALLOW_SELF_SIGNED_CERT", default: false) }

    private func environment(_ key: String, default: String = "") -> String {
        ProcessInfo.processInfo.environment[key] ?? `default`
    }

    private func environment(_ key: String, default: Bool = false) -> Bool {
        let string = environment(key, default: "false")
        return Bool(argument: string) ?? `default`
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
