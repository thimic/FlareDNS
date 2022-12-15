//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging
import CollectionConcurrencyKit


struct FlareDNSController {
        
    var model: FlareDNSModel
    let cloudflareAPI: CloudFlareAPI
    let ipV4Lookup: IPv4LookupAPI
    
    init(model: FlareDNSModel, ipV4Lookup: IPv4LookupAPI) throws {
        self.model = model
        self.ipV4Lookup = ipV4Lookup
        guard let apiToken = model.apiToken else {
            throw FlareDNSError.missingAPIToken
        }
        cloudflareAPI = CloudFlareAPI(apiToken: apiToken)
    }

    func run() async throws -> [String] {
        async let records = try await model.getRecordsWithIds(cloudflareAPI)
        async let ip = try await getIP()
        return try await records.concurrentMap { [ip] record in
            try await cloudflareAPI.updateDNSRecord(record: record, ip: ip)
        }
    }

    private func getIP() async throws -> DNSContent {
        try await ipV4Lookup.getIP()
    }

    private func checkZones() async throws -> [Zone] {
        let zones = try await cloudflareAPI.listZones(zoneNames: model.configZoneNames.sorted())
        let resultZoneNames = zones.map(\.name)
        guard model.configZoneNames.sorted() == resultZoneNames.sorted() else {
            throw FlareDNSError.zoneMismatch(expected: model.configZoneNames, actual: resultZoneNames)
        }
        return zones
    }

    private func getRecords(_ zones: [Zone]) async throws -> [DNSRecordResponse] {
        try await zones.concurrentFlatMap(cloudflareAPI.listDNSRecords)
    }

    @discardableResult
    private func checkRecords(_ records: [DNSRecordResponse]) throws -> [DNSRecordResponse] {
        var invalidRecords: [String] = []
        var lockedRecords: [String] = []

        for configRecord in model.records {
            guard let apiRecord = records.filter({ apiRecord in apiRecord.name == configRecord.name }).first else {
                invalidRecords.append(configRecord.name)
                continue
            }
            guard !apiRecord.locked else {
                lockedRecords.append(configRecord.name)
                continue
            }
        }

        guard invalidRecords.isEmpty else {
            throw FlareDNSError.missingRecords(records: invalidRecords)
        }

        guard lockedRecords.isEmpty else {
            throw FlareDNSError.lockedRecords(records: lockedRecords)
        }
        return records
    }

    func check() async throws -> String {
        guard !model.configZoneNames.isEmpty else {
            throw FlareDNSError.noRecords
        }
        let zones = try await checkZones()
        let records = try await getRecords(zones)
        try checkRecords(records)
        return "Done!"
    }
    
}
