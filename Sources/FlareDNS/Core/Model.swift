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
            guard newValue?.rawValue == Config.shared.string(forKey: "config:auth:apiToken") else {
                Logger.shared.info("New API token value is identical to the previous")
                return
            }
            Config.shared.set(newValue?.rawValue, forKey: "config:auth:apiToken")
            Logger.shared.info("API token was set")
        }
    }
    var updateInterval: Int {
        get {
            let configUpdateInterval = Config.shared.integer(forKey: "config:run:updateInterval")
            guard configUpdateInterval != 0 else {
                return 1800
            }
            return configUpdateInterval
        }
        set {
            guard newValue != Config.shared.integer(forKey: "config:run:updateInterval") else {
                Logger.shared.info("New update interval is identical to the previous")
                return
            }
            Config.shared.set(newValue, forKey: "config:run:updateInterval")
            Logger.shared.info("Update interval was set to \(updateInterval)")
        }
    }
    var records: [DNSRecord]
    private (set) var zones: [Zone]? = nil
    
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
