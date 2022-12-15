//
//  IPv4Lookupable.swift
//  
//
//  Created by Michael Thingnes on 11/12/22.
//

import Foundation

protocol IPv4Lookupable {

    typealias DNSHandler = (Data) -> DNSContent?

    var name: String { get }
    var sessionType: SessionType { get }
    var login: Login? { get }
    var endpoint: URL { get }
    var dataHandler: DNSHandler { get }

}


extension IPv4Lookupable {
    var sessionType: SessionType { .standard }
    var login: Login? { nil }
    var dataHandler: DNSHandler {
        { data in
            String(data: data, encoding: .utf8)
                .map { DNSContent(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }
    }
}

struct Login {

    typealias Headers = [String: String]
    typealias Body = [String: String]

    let method: RequestManager.Method
    let url: URL
    let headers: Headers?
    let body: Body

}
