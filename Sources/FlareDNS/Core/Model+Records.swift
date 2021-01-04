//
//  File.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import Foundation
import Logging


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
    
    mutating func removeRecord(recordName: String) -> Result<String, Error> {
        
        // Remove record with same name if it exists
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == recordName
        }
        if filteredRecords.count > 0 {
            let oldRecord = filteredRecords.first!
            let index = records.firstIndex(of: oldRecord)!
            records.remove(at: index)
        } else {
            return Result.failure(
                FlareDNSError("No records matching record name \"\(recordName)\"")
            )
        }
        
        // Persist records
        persistRecords()
        return Result.success("Removed record \"\(filteredRecords.first!.name)\"")

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
    
}
