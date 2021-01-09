
import Foundation
import Logging
import PromiseKit


#if os(Linux)
import FoundationNetworking
#endif


struct CloudFlareAPI {
    
    let requestManager: RequestManager
    
    init(apiToken: ApiToken) {
        var manager = RequestManager()
        manager.authorize(with: apiToken)
        requestManager = manager
    }
    
    private struct Endpoint {
        
        var components: URLComponents
        var url: URL? { components.url }
        
        init(_ path: String, queryItems: [URLQueryItem]? = nil) {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "api.cloudflare.com"
            components.path = URL(string: "/client/v4")!.appendingPathComponent(path).path
            components.queryItems = queryItems
            self.components = components
        }
        
    }
    
    func listZones(zoneNames: [String]?) -> Promise<[Zone]> {
        return Promise { seal in
            var queryItems: [URLQueryItem]? = nil
            if let zoneNames = zoneNames {
                queryItems = [URLQueryItem(name: "name", value: zoneNames.joined(separator: ","))]
            }
            let endpoint = Endpoint("zones", queryItems: queryItems)
            guard let url = endpoint.url else {
                seal.reject(FlareDNSError("Unable to construct valid URL with \(endpoint.components)"))
                return
            }
            requestManager.get(from: url)
                .done { data in
                    struct ResponseBody: Decodable {
                        let result: [Zone]
                    }

                    let decoder = JSONDecoder()
                    do {
                        let responseBody = try decoder.decode(ResponseBody.self, from: data)
                        seal.fulfill(responseBody.result)
                    } catch {
                        seal.reject(error)
                    }
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    func listDNSRecords(zone: Zone) -> Promise<[DNSRecordResponse]> {
        return Promise { seal in
            guard let zoneID = zone.id else {
                seal.reject(FlareDNSError("Missing zone ID for zone \"\(zone.name)\""))
                return
            }
            
            let endpoint = Endpoint("zones/\(zoneID)/dns_records")
            guard let url = endpoint.url else {
                seal.reject(FlareDNSError("Unable to construct valid URL with \(endpoint.components)"))
                return
            }
            
            requestManager.get(from: url)
                .done { data in
                    struct ResponseBody: Decodable {
                        let result: [DNSRecordResponse]
                    }
                    
                    let decoder = JSONDecoder()
                    do {
                        let responseBody = try decoder.decode(ResponseBody.self, from: data)
                        seal.fulfill(responseBody.result)
                    } catch {
                        seal.reject(error)
                    }
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    /// Update given DNS record to the given IP address.
    /// - Parameters:
    ///   - record: Cloudflare record to update
    ///   - ip:     IP address to update record with
    func updateDNSRecord(record: DNSRecord, ip: DNSContent) -> Promise<String> {
        return Promise { seal in
            
            guard let zoneId = record.zone.id else {
                seal.reject(FlareDNSError("No ID found for zone \"\(record.zone.name)\""))
                return
            }
            
            guard let recordId = record.id else {
                seal.reject(FlareDNSError("No ID found for record \"\(record.name)\""))
                return
            }
            
            let endpoint = Endpoint("zones/\(zoneId)/dns_records/\(recordId)")
            guard let url = endpoint.url else {
                seal.reject(FlareDNSError("Unable to construct valid URL with \(endpoint.components)"))
                return
            }
            
            let encoder = JSONEncoder()
            guard let requestBody = try? encoder.encode(record.createRequest(ip: ip)) else {
                seal.reject(FlareDNSError("Unable to encode request body: \(record)"))
                return
            }
            requestManager.put(from: url, httpBody: requestBody)
                .done { data in
                    seal.fulfill("Record \"\(record.name)\" was updated with IP \(ip.rawValue)")
                }
                .catch { error in
                    seal.reject(error)
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
