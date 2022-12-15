
import Foundation
import Logging

#if os(Linux)
import FoundationNetworking
#endif


struct CloudFlareAPI {
    
    let requestManager: RequestManager
    
    init(apiToken: ApiToken) {
        let manager = RequestManager()
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

    func listZones(zoneNames: [String]?) async throws -> [Zone] {
        var queryItems: [URLQueryItem]? = nil
        if let zoneNames = zoneNames {
            queryItems = [URLQueryItem(name: "name", value: zoneNames.joined(separator: ","))]
        }
        let endpoint = Endpoint("zones", queryItems: queryItems)
        guard let url = endpoint.url else {
            throw FlareDNSError.invalidURL(fromComponents: endpoint.components)
        }
        let data = try await requestManager.get(from: url)

        struct ResponseBody: Decodable {
            let result: [Zone]
        }

        let responseBody = try JSONDecoder().decode(ResponseBody.self, from: data)
        return responseBody.result
    }

    func listDNSRecords(zone: Zone) async throws -> [DNSRecordResponse] {
        guard let zoneID = zone.id else {
            throw FlareDNSError.missingZoneID(zoneName: zone.name)
        }

        let endpoint = Endpoint("zones/\(zoneID)/dns_records")
        guard let url = endpoint.url else {
            throw FlareDNSError.invalidURL(fromComponents: endpoint.components)
        }

        let data = try await requestManager.get(from: url)

        struct ResponseBody: Decodable {
            let result: [DNSRecordResponse]
        }

        let responseBody = try JSONDecoder().decode(ResponseBody.self, from: data)
        return responseBody.result

    }

    /// Update given DNS record to the given IP address.
    /// - Parameters:
    ///   - record: Cloudflare record to update
    ///   - ip:     IP address to update record with
    func updateDNSRecord(record: DNSRecord, ip: DNSContent) async throws -> String {

        guard let zoneId = record.zone.id else {
            throw FlareDNSError.missingZoneID(zoneName: record.zone.name)
        }

        guard let recordId = record.id else {
            throw FlareDNSError.missingRecordID(recordName: record.name)
        }

        let endpoint = Endpoint("zones/\(zoneId)/dns_records/\(recordId)")
        guard let url = endpoint.url else {
            throw FlareDNSError.invalidURL(fromComponents: endpoint.components)
        }

        let requestBody = try JSONEncoder().encode(record.createRequest(ip: ip))
        try await requestManager.put(from: url, httpBody: requestBody)
        return "Record \"\(record.name)\" was updated with IP \(ip.rawValue)"
    }

}
