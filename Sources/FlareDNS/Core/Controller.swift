//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging
import PromiseKit


struct FlareDNSController {
        
    let model: FlareDNSModel
    let cloudflareAPI: CloudFlareAPI
    
    init?() {
        model = FlareDNSModel.shared
        guard let apiToken = model.apiToken else {
            return nil
        }
        cloudflareAPI = CloudFlareAPI(apiToken: apiToken)
    }
    
    func run() {

    }
    
    private func checkZones() -> Promise<[Zone]> {
        return Promise { seal in
            cloudflareAPI.listZones(zoneNames: FlareDNSModel.shared.configZoneNames.sorted())
                .done { zones in
                    let resultZoneNames = zones.map { zone in
                        return zone.name
                    }
                    guard FlareDNSModel.shared.configZoneNames.sorted() == resultZoneNames.sorted() else {
                        seal.reject(FlareDNSError(
                            "Expected data for zone(s) [\(FlareDNSModel.shared.configZoneNames.sorted().joined(separator: ", "))], " +
                            "but only received data for zone(s) [\(resultZoneNames.sorted().joined(separator: ", "))]"
                        ))
                        return
                    }
                    seal.fulfill(zones)
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    private func getRecords(_ zones: [Zone]) -> Promise<[DNSRecordResponse]> {
        return Promise { seal in
            when(fulfilled: zones.map(cloudflareAPI.listDNSRecords))
                .done { records in
                    seal.fulfill(records.flatMap { $0 })
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
    private func checkRecords(_ records: [DNSRecordResponse]) -> Promise<[DNSRecordResponse]> {
        return Promise { seal in
            
            var validRecords: [DNSRecordResponse] = []
            var invalidRecords: [String] = []
            var lockedRecords: [String] = []
            
            for record in FlareDNSModel.shared.records {
                guard let apiRecord = records.filter({ apiRecord in apiRecord.name == record.name }).first else {
                    invalidRecords.append(record.name)
                    continue
                }
                guard !apiRecord.locked else {
                    lockedRecords.append(record.name)
                    continue
                }
                validRecords.append(apiRecord)
            }

            guard invalidRecords.isEmpty else {
                seal.reject(FlareDNSError("The following records are not available via the Cloudflare API: \n - \(invalidRecords.joined(separator: "\n - "))"))
                return
            }
            
            guard lockedRecords.isEmpty else {
                seal.reject(FlareDNSError("The following records are locked in the Cloudflare API and cannot be edited: \n - \(lockedRecords.joined(separator: "\n - "))"))
                return
            }
            seal.fulfill(validRecords)
        }
    }
    
    func check() -> Promise<String> {
        return Promise { seal in
            
            guard !FlareDNSModel.shared.configZoneNames.isEmpty else {
                seal.reject(FlareDNSError("No records have been added to the configuration"))
                return
            }
            
            firstly {
                checkZones()
            }
            .then { zones in
                getRecords(zones)
            }
            .then { records in
                checkRecords(records)
            }
            .done { records in
                print(records)
                seal.fulfill("Done!")
            }
            .catch { error in
                seal.reject(error)
            }
            
        }
    }
    
}
