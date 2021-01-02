//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging

struct FlareDNSModelError: Error {
    let message: String
}


struct FlareDNSModel {
    
    static var shared = FlareDNSModel()
    
    var apiToken: ApiToken? {
        get {
            guard let token = Config.shared.string(forKey: "config:auth:apiToken") else {
                return nil
            }
            return ApiToken(rawValue: token)
        }
        set {
            if newValue?.rawValue != Config.shared.string(forKey: "config:auth:apiToken") {
                Config.shared.set(newValue?.rawValue, forKey: "config:auth:apiToken")
                Logger.shared.info("API token was set")
            }
            Logger.shared.info("New API token value is identical to the previous")
        }
    }
    
    var records: [DNSRecord]
    
    init() {
        
        // Load records
        if let rawRecords = Config.shared.array(forKey: "config:records:records") as? [Data] {
            let decoder = PropertyListDecoder()
            var decodedRecords: [DNSRecord] = []
            for rawRecord in rawRecords {
                if let record = try? decoder.decode(DNSRecord.self, from: rawRecord) {
                    decodedRecords.append(record)
                }
            }
            self.records = decodedRecords
        } else {
            self.records = [DNSRecord]()
        }
    }
    
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
        records.append(record)
        
        // Persist records
        persistRecords()
    }
    
    mutating func removeRecord(zoneName: String, recordName: String) -> Result<String, FlareDNSModelError> {
        
        // Remove record with same zone and name if it exists
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == recordName && existingRecord.zone.name == zoneName
        }
        if filteredRecords.count > 0 {
            let oldRecord = filteredRecords.first!
            let index = records.firstIndex(of: oldRecord)!
            records.remove(at: index)
        } else {
            return Result.failure(
                FlareDNSModelError(
                    message: "No records matching zone name \"\(zoneName)\" and record name \"\(recordName)\""
                )
            )
        }
        
        // Persist records
        persistRecords()
        Logger.shared.info("Removed record \(filteredRecords.first!.description)")
        return Result.success("Removed record \(filteredRecords.first!.description)")

    }
    
    func getRecord(zoneName: String, recordName: String) -> DNSRecord? {
        let filteredRecords = records.filter { (existingRecord) -> Bool in
            existingRecord.name == recordName && existingRecord.zone.name == zoneName
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
        
        var dataArray = [Data]()
        for record in records {
            var encodedRecord: Data? = nil
            do {
                encodedRecord = try encoder.encode(record)
            } catch {
                Logger.shared.error("Unable to encode record \(record.description): \(error.localizedDescription)")
                continue
            }
            if let encodedRecord = encodedRecord {
                dataArray.append(encodedRecord)
            }
        }
        Config.shared.set(dataArray, forKey: "config:records:records")

    }
    
}
