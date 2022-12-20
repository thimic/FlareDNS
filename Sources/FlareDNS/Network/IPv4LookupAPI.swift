//
//  File.swift
//  
//
//  Created by Michael Thingnes on 15/12/20.
//

import Foundation
import Logging


struct IPv4LookupAPI {
        
    private let requestManager = RequestManager()

    func getIP() async throws -> DNSContent {
        for lookup in IPv4Lookup.allCases {
            do {
                let dnsContent = try await lookup.getIP(requestManager: requestManager)
                return dnsContent
            } catch {
                Logger.shared.warning("Unable to look up IP using \(lookup.endpoint): \(error)")
            }
        }
        throw FlareDNSError.allLookupsFailed
    }
    
}
