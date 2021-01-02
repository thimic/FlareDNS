
import CoreFoundation
import Foundation
import Logging

#if os(Linux)
import FoundationNetworking
#endif

let apiURL = URL(string: "https://api.cloudflare.com/client/v4/")!


struct DataLoader {

    typealias Handler = (Result<Data, Error>) -> Void
    
    var urlSession = URLSession.shared
    var headers: [String: String] = ["Content-Type": "application/json"]
    
    func loadData(from url: URL, then handler: @escaping Handler) {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        urlSession.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else { return }
            if let data = data {
                handler(.success(data))
                return
            }
            if let error = error {
                handler(.failure(error))
                return
            }
        }.resume()
    }
    
    func sendData(from url: URL, body: Data?, then handler: @escaping Handler) {
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = "PUT"
        request.httpBody = body
        urlSession.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else { return }
            if let data = data {
                handler(.success(data))
                return
            }
            if let error = error {
                handler(.failure(error))
                return
            }
        }.resume()
    }
}

extension DataLoader {
    mutating func authorize(with token: ApiToken) {
        headers["Authorization"] = "Bearer \(token.rawValue)"
    }
}


func requestIP(ipLookup: IPv4Lookups, completion: @escaping (IPAddress) -> Void) {
    let dataLoader = DataLoader()
    dataLoader.loadData(from: ipLookup.value.endpoint) { result in
        switch result {
        case .success(let data):
            if let ip = ipLookup.value.decode(data) {
                completion(ip)
            }
        case .failure(let error):
            Logger.shared.error("\(error.localizedDescription)")
        }
    }
}


func listDNSRecords(zone: Zones) {
    let endpoint = apiURL.appendingPathComponent("zones/\(zone.rawValue)/dns_records")
    var dataLoader = DataLoader()
    dataLoader.authorize(with: token)
    dataLoader.loadData(from: endpoint) { result in
        switch result {
        case .success(let data):
            Logger.shared.info("\(String(data: data, encoding: .utf8) ?? "Unable to parse response body")")
        case .failure(let error):
            Logger.shared.error("Failed to list records: \(error.localizedDescription)")
        }
    }
}

struct DNSRecordBody: Codable {
    
    enum Types: String, Codable, CaseIterable {
        case A, AAAA, CNAME
    }
    
    var type: Types
    let name: String
    var content: IPAddress
    var ttl: Int = 1800
    let proxied: Bool
}

var currentIP: IPAddress? = nil


/// Update DNS A record for the given zone and record with the IP of this host.
/// - Parameters:
///   - zone: Cloudflare Zone id
///   - record: Cloudflare record to update
func updateDNSRecord(zone: Zones, records: [Records]) {
//    for lookup in IPv4Lookups.allCases {
    requestIP(ipLookup: .googleWifi) { ip in
        if let curIP = currentIP {
            if ip == curIP {
                Logger.shared.info("IP is unchanged")
                return
            }
        }
        currentIP = ip
        let encoder = JSONEncoder()
        for record in records {
            let body = DNSRecordBody(type: .A, name: record.name, content: ip, ttl: 1, proxied: true)
            
            let endpoint = apiURL.appendingPathComponent("zones/\(zone.rawValue)/dns_records/\(record.id)")
            var dataLoader = DataLoader()
            dataLoader.authorize(with: token)
            dataLoader.sendData(from: endpoint, body: try? encoder.encode(body)) { result in
                switch result {
                case .success:
                    Logger.shared.info("Updated \(record.name): \(ip.rawValue)")
                case .failure(let error):
                    Logger.shared.error("Failed to update \(record.name) to \(ip.rawValue): \(error.localizedDescription)")
                }
            }
        }
    }
}


//if #available(OSX 10.12, *) {
//    logger.info("Started FlareDNS")
//    startTimer()
//} else {
//    logger.critical("Unsupported OS, terminating.")
//    exit(EXIT_FAILURE)
//}
