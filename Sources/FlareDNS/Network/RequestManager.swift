//
//  File.swift
//  
//
//  Created by Michael Thingnes on 4/01/21.
//

import Foundation
import PromiseKit


#if os(Linux)
import FoundationNetworking
#endif

struct RequestManager {
    
    var urlSession = URLSession.shared
    var headers: [String: String] = ["Content-Type": "application/json"]
    
    private func request(from url: URL, method: String = "GET", httpBody: Data? = nil) -> Promise<Data> {
        return Promise { seal in
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.allHTTPHeaderFields = headers
            request.httpBody = httpBody
            urlSession.dataTask(with: request) { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    seal.reject(error ?? FlareDNSError("No response from API"))
                    return
                }
                guard 200..<300 ~= httpResponse.statusCode else {
                    seal.reject(error ?? FlareDNSError(httpResponse.description))
                    return
                }
                guard let data = data else {
                    seal.reject(error ?? FlareDNSError("Unknown Error"))
                    return
                }
                seal.fulfill(data)
            }.resume()
        }
    }
    
    func get(from url: URL) -> Promise<Data> {
        request(from: url, method: "GET")
    }
    
    func post(from url: URL) -> Promise<Data> {
        request(from: url, method: "POST")
    }

    func put(from url: URL, httpBody: Data) -> Promise<Data> {
        request(from: url, method: "PUT", httpBody: httpBody)
    }
    
}


extension RequestManager {
    mutating func authorize(with token: ApiToken) {
        headers["Authorization"] = "Bearer \(token.rawValue)"
    }
}
