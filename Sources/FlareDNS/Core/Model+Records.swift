//
//  File.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import Foundation
import Logging
import PromiseKit


extension FlareDNSModel {
    
    mutating func addRecord(_ record: DNSRecord) {
        
        // Remove record with same zone and name if it exists
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == record.name && existingRecord.zone == record.zone
        }
        if filteredRecords.count > 0 {
            let oldRecord = filteredRecords.first!
            let index = records.firstIndex(of: oldRecord)!
            records.remove(at: index)
        }
        
        // Add new record
        records.insert(record, at: 0)
        
        // Persist records
        persistRecords()
    }
    
    mutating func removeRecord(recordName: String) -> Swift.Result<String, Error> {
        
        // Remove record with same name if it exists
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == recordName
        }
        if filteredRecords.count > 0 {
            let oldRecord = filteredRecords.first!
            let index = records.firstIndex(of: oldRecord)!
            records.remove(at: index)
        } else {
            return Swift.Result.failure(
                FlareDNSError("No records matching record name \"\(recordName)\"")
            )
        }
        
        // Persist records
        persistRecords()
        return Swift.Result.success("Removed record \"\(filteredRecords.first!.name)\"")

    }
    
    func getRecord(recordName: String) -> DNSRecord? {
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == recordName
        }
        if filteredRecords.count > 0 {
            return filteredRecords.first!
        }
        return nil
    }
    
    mutating func removeAllRecords() {
        records.removeAll()
        persistRecords()
    }
    
    private func persistRecords() {
        let encoder = PropertyListEncoder()
        
        var dataArray: [Data] = []
        for record in records {
            var encodedRecord: Data? = nil
            do {
                encodedRecord = try encoder.encode(record)
            } catch {
                Logger.shared.error("Unable to encode record \"\(record.name)\": \(error.localizedDescription)")
                continue
            }
            if let encodedRecord = encodedRecord {
                dataArray.append(encodedRecord)
            }
        }
        Config.shared.set(dataArray, forKey: "config:records:records")

    }
        
    func getRecordsWithIds(_ cloudFlareAPI: CloudFlareAPI) -> Promise<[DNSRecord]> {
        return Promise { seal in
            cloudFlareAPI.listZones(zoneNames: configZoneNames)
                .thenFlatMap { zone in
                    cloudFlareAPI.listDNSRecords(zone: zone)
                }
                .done { apiRecords in
                    var updatedRecords: [DNSRecord] = records
                    for (index, configRecord) in updatedRecords.enumerated() {
                        guard let apiRecord = apiRecords.filter({ record in record.name == configRecord.name }).first else {
                            // TODO: Reject?
                            Logger.shared.warning("Unable to find record \(configRecord.name) at Cloudflare")
                            continue
                        }
                        var newRecord = configRecord
                        newRecord.zone.id = apiRecord.zoneID
                        newRecord.id = apiRecord.id
                        updatedRecords[index] = newRecord
                    }
                    seal.fulfill(updatedRecords)
                }
                .catch { error in
                    seal.reject(error)
                }
        }
    }
    
}
