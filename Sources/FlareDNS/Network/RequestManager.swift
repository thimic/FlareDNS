//
//  RequestManager.swift
//  
//
//  Created by Michael Thingnes on 4/01/21.
//

import AsyncHTTPClient
import Foundation
import Logging
import NIOCore
import NIOHTTP1
import NIOSSL
import NIOPosix


actor RequestManager {

    typealias Headers = [String: String]

    var cookie: String?
    var authorization: String?

    var headers: HTTPHeaders = ["Content-Type": "application/json"]

    init(authorization: String? = nil) {
        self.authorization = authorization
    }

    @discardableResult
    func request(
        from url: URL,
        method: HTTPMethod = .GET,
        headers: HTTPHeaders? = nil,
        body: Data? = nil,
        certificateVerification: CertificateVerification = .fullVerification
    ) async throws -> ByteBuffer {
        let client = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: .init(certificateVerification: certificateVerification)
        )
        defer {
            do {
                try client.syncShutdown()
            } catch {
                Logger.shared.error("Failed to shut down HTTPClient: \(error.localizedDescription)")
            }
        }

        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = method
        request.headers = completeHeaders(headers)
        request.body = body.map { .bytes(.init(data: $0)) }

        let response = try await client.execute(request, timeout: .seconds(30))
        guard response.status == .ok else {
            throw FlareDNSError.errorResponse(responseStatus: response.status)
        }
        if let cookie = response.headers.first(name: "Set-Cookie") {
            self.cookie = cookie
        }
        return try await response.body.collect(upTo: 1024 * 1024)
    }

    func get(from url: URL, certificateVerification: CertificateVerification = .fullVerification) async throws -> ByteBuffer {
        try await request(from: url, method: .GET, certificateVerification: certificateVerification)
    }

    func post(from url: URL, certificateVerification: CertificateVerification = .fullVerification) async throws -> ByteBuffer {
        try await request(from: url, method: .POST, certificateVerification: certificateVerification)
    }

    @discardableResult
    func put(from url: URL, body: Data, certificateVerification: CertificateVerification = .fullVerification) async throws -> ByteBuffer {
        try await request(from: url, method: .PUT, body: body, certificateVerification: certificateVerification)
    }
    
}


extension RequestManager {

    private func completeHeaders(_ headers: HTTPHeaders? = nil) -> HTTPHeaders {
        var allHeaders = self.headers
        if let headers {
            allHeaders.replaceOrAdd(contentsOf: headers)
        }
        if let cookie {
            allHeaders.replaceOrAdd(name: "Cookie", value: cookie)
        }
        if let authorization {
            allHeaders.replaceOrAdd(name: "Authorization", value: authorization)
        }
        return allHeaders
    }

}


extension HTTPHeaders {

    mutating func replaceOrAdd(contentsOf other: HTTPHeaders) {
        for (name, value) in other {
            self.replaceOrAdd(name: name, value: value)
        }
    }

}
