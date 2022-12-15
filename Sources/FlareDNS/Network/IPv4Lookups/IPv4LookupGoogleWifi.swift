//
//  IPv4LookupGoogleWifi.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation


struct IPv4LookupGoogleWifi: IPv4Lookupable {

    let name = "Google Wifi"
    let endpoint = URL(string: "http://onhub.here/api/v1/status")!

    var dataHandler: DNSHandler = { data in
        try? JSONDecoder().decode(GoogleWifi.self, from: data).wan.localIpAddress
    }

}

private extension IPv4LookupGoogleWifi {

    struct Wan: Codable {
        let localIpAddress: DNSContent
    }

    struct GoogleWifi: Codable {
        let wan: Wan
    }

}
