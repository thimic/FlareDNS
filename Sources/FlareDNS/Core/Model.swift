//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging


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
    var zones: [Zone]? = nil
    
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
}
