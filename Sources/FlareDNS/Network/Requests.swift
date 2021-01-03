//
//  File.swift
//  
//
//  Created by Michael Thingnes on 17/12/20.
//

import Foundation
import PromiseKit

#if os(Linux)
import FoundationNetworking
#endif


func fetchIP(url: URL?) -> Promise<Data> {
    Promise { seal in
        URLSession.shared.dataTask(with: url!) { data, _, error in
            seal.resolve(data, error)
        }.resume()
    }
}


func putRecord(request: URLRequest, ip: IPAddress) -> Promise<URLResponse> {
    Promise { seal in
        URLSession.shared.dataTask(with: request) { _, response, error in
            seal.resolve(response, error)
        }.resume()
    }
}


func attempt<T>(_ body: @escaping () -> Promise<T>) -> Promise<T> {
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < maximumRetryCount else { throw error }
            return after(delayBeforeRetry).then(on: nil, attempt)
        }
    }
    return attempt()
}


func updateRecord() {
    firstly {
        fetchIP(url: IPv4Lookups.googleWifi.value.endpoint)
    }.then { data in
        
        let url = URL(string: "")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = ["ip": ip]
        return putRecord(request: request, ip: ip)
    }
}
