//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging
import CollectionConcurrencyKit


actor FlareDNSController {

    enum RunResult {
        case noChange(ip: DNSContent)
        case updated(records: [String])
    }
        
    var model: FlareDNSModel
    let cloudflareAPI: CloudFlareAPI
    let ipV4Lookup: IPv4LookupAPI

    private var lastIP: DNSContent? = nil
    
    init(model: FlareDNSModel, ipV4Lookup: IPv4LookupAPI) throws {
        self.model = model
        self.ipV4Lookup = ipV4Lookup
        guard let apiToken = model.apiToken else {
            throw FlareDNSError.missingAPIToken
        }
        cloudflareAPI = CloudFlareAPI(apiToken: apiToken)
    }

    func run() async throws -> RunResult {
        let ip = try await getIP()
        if let lastIP {
            if ip == lastIP {
                return .noChange(ip: ip)
            }
        }
        lastIP = ip
        async let records = try model.getRecordsWithIds(cloudflareAPI)
        let updatedRecords = try await records.concurrentMap { [cloudflareAPI] record in
            try await cloudflareAPI.updateDNSRecord(record: record, ip: ip)
        }
        return .updated(records: updatedRecords)
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

extension FlareDNSController.RunResult {

    func log() {
        switch self {
        case .noChange(let ip):
            Logger.shared.info("\("IP has not changed: \(ip.rawValue)".blue())")
        case .updated(let records):
            for record in records {
                Logger.shared.info("\(record.cyan())")
            }
        }
    }

}
