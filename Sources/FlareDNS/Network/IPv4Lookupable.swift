//
//  IPv4Lookupable.swift
//  
//
//  Created by Michael Thingnes on 11/12/22.
//

import Foundation
import NIOCore
import NIOHTTP1
import NIOSSL

protocol IPv4Lookupable {

    typealias DNSHandler = (ByteBuffer) -> DNSContent?

    var name: String { get }
    var certificateVerification: CertificateVerification { get }
    var login: Login? { get }
    var endpoint: URL { get }
    var dataHandler: DNSHandler { get }

}


extension IPv4Lookupable {
    var certificateVerification: CertificateVerification { .fullVerification }
    var login: Login? { nil }
    var dataHandler: DNSHandler {
        { data in
            let dns = String(buffer: data)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return DNSContent(rawValue: dns)
        }
    }
}

struct Login {

    typealias Body = [String: String]

    let method: HTTPMethod
    let url: URL
    let headers: HTTPHeaders?
    let body: Body

}
