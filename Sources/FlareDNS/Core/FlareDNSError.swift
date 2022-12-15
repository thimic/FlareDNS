//
//  FlareDNSError.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif


enum FlareDNSError: LocalizedError {

    case allLookupsFailed
    case configSaveFailed
    case errorResponse(response: HTTPURLResponse)
    case invalidResponse
    case invalidURL(fromComponents: URLComponents)
    case lockedRecords(records: [String])
    case lookupFailed(endpoint: URL)
    case missingAPIToken
    case missingRecordID(recordName: String)
    case missingRecords(records: [String])
    case missingZoneID(zoneName: String)
    case noRecords
    case removeRecordFailed(recordName: String)
    case zoneMismatch(expected: [String], actual: [String])

    public var errorDescription: String? {
        switch self {
        case .allLookupsFailed:
            return "All lookups failed"
        case .configSaveFailed:
            return "Failed to encode and store config data"
        case .errorResponse(response: let response):
            return "\(response.statusCode) - \(response.description)"
        case .invalidResponse:
            return "Invalid HTTP response from API"
        case .invalidURL(fromComponents: let components):
            return "Unable to construct valid URL with \(components)"
        case .lockedRecords(records: let records):
            return "The following records are locked in the Cloudflare API and cannot be edited: \n - \(records.joined(separator: "\n - "))"
        case .lookupFailed(endpoint: let endpoint):
            return "Unable to opdatin IP address using \(endpoint.path)"
        case .missingAPIToken:
            return "Missing API Token"
        case .missingRecordID(recordName: let name):
            return "No ID found for record \"\(name)\""
        case .missingRecords(records: let records):
            return "The following records are not available via the Cloudflare API: \n - \(records.joined(separator: "\n - "))"
        case .missingZoneID(zoneName: let name):
            return "No ID found for zone \"\(name)\""
        case .noRecords:
            return "No records have been added to the configuration"
        case .removeRecordFailed(recordName: let name):
            return "No records matching record name \"\(name)\""
        case .zoneMismatch(expected: let expected, actual: let actual):
            return "Expected data for zone(s) [\(expected.sorted().joined(separator: ", "))], " +
            "but only received data for zone(s) [\(actual.sorted().joined(separator: ", "))]"
        }
    }
}
