//
//  File.swift
//  
//
//  Created by Michael Thingnes on 4/01/21.
//

import Foundation
import RegexBuilder

#if os(Linux)
import FoundationNetworking
#endif

final class RequestManager: NSObject {

    typealias Headers = [String: String]

    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    var cookie: String?
    var authorization: String?

    var headers: Headers = ["Content-Type": "application/json"]

    private lazy var urlSession = URLSession.shared
    private lazy var insecureUrlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    @discardableResult
    func request(from url: URL, method: Method = .get, headers: Headers? = nil, httpBody: Data? = nil, sessionType: SessionType = .standard) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = completeHeaders(headers)
        request.httpBody = httpBody
        let (data, response) = try await session(sessionType).data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FlareDNSError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw FlareDNSError.errorResponse(response: httpResponse)
        }
        if let cookie = httpResponse.value(forHTTPHeaderField: "Set-Cookie") {
            self.cookie = cookie
        }
        return data
    }

    func get(from url: URL, sessionType: SessionType = .standard) async throws -> Data {
        try await request(from: url, method: .get, sessionType: sessionType)
    }

    func post(from url: URL, sessionType: SessionType = .standard) async throws -> Data {
        try await request(from: url, method: .post, sessionType: sessionType)
    }

    @discardableResult
    func put(from url: URL, httpBody: Data, sessionType: SessionType = .standard) async throws -> Data {
        try await request(from: url, method: .put, httpBody: httpBody, sessionType: sessionType)
    }

    private func session(_ sessionType: SessionType) -> URLSession {
        switch sessionType {
        case .standard:
            return urlSession
        case .insecure:
            return insecureUrlSession
        }
    }
    
}


extension RequestManager {

    func authorize(with token: ApiToken) {
        authorization = "Bearer \(token.rawValue)"
    }

    private func completeHeaders(_ headers: Headers? = nil) -> Headers {
        var allHeaders = self.headers
        if let headers {
            allHeaders.merge(headers) { lhs, rhs in rhs }
        }
        if let cookie {
            allHeaders["Cookie"] = cookie
        }
        if let authorization {
            allHeaders["Authorization"] = authorization
        }
        return allHeaders
    }

}


extension RequestManager: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        #if os(Linux)
        // Self signed certs are not supported on Linux: https://forums.swift.org/t/handling-self-signed-certificates-in-urlauthenticationchallenge-on-linux/22575
        return (.performDefaultHandling, nil)
        #else
        return (.useCredential, challenge.protectionSpace.serverTrust.map { URLCredential(trust: $0) })
        #endif
    }

}
