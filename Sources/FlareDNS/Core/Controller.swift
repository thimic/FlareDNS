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
        
    var model: FlareDNSModel
    let cloudflareAPI: CloudFlareAPI
    
    init?() {
        model = FlareDNSModel.shared
        guard let apiToken = model.apiToken else {
            return nil
        }
        cloudflareAPI = CloudFlareAPI(apiToken: apiToken)
    }
    
    private func updateRecords() -> Promise<[String]> {
        return Promise { seal in
            firstly {
                when(fulfilled: model.getRecordsWithIds(cloudflareAPI), IPv4LookupAPI.shared.getIP())
            }
            .then { records, ip in
                when(fulfilled: records.map({ record in cloudflareAPI.updateDNSRecord(record: record, ip: ip) }))
            }
            .done { reports in
                seal.fulfill(reports)
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    @available(OSX 10.12, *)
    func run() -> Promise<[String]> {
        return Promise { seal in
            updateRecords()
                .done { messages in
                    seal.fulfill(messages)
                }
                .catch{ error in
                    seal.reject(error)
                }
        }
    }
    
    private func checkZones() -> Promise<[Zone]> {
        return Promise { seal in
            cloudflareAPI.listZones(zoneNames: model.configZoneNames.sorted())
                .done { zones in
                    let resultZoneNames = zones.map { zone in
                        return zone.name
                    }
                    guard model.configZoneNames.sorted() == resultZoneNames.sorted() else {
                        seal.reject(FlareDNSError(
                            "Expected data for zone(s) [\(model.configZoneNames.sorted().joined(separator: ", "))], " +
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
                seal.reject(FlareDNSError("The following records are not available via the Cloudflare API: \n - \(invalidRecords.joined(separator: "\n - "))"))
                return
            }
            
            guard lockedRecords.isEmpty else {
                seal.reject(FlareDNSError("The following records are locked in the Cloudflare API and cannot be edited: \n - \(lockedRecords.joined(separator: "\n - "))"))
                return
            }
            seal.fulfill(records)
        }
    }
    
    func check() -> Promise<String> {
        return Promise { seal in
            
            guard !model.configZoneNames.isEmpty else {
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
                seal.fulfill("Done!")
            }
            .catch { error in
                seal.reject(error)
            }
            
        }
    }
    
}
