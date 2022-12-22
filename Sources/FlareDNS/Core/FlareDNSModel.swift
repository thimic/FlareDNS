//
//  FlareDNSModel.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation
import Logging


class FlareDNSModel {
    
    var apiToken: ApiToken? {
        get {
            guard let token = config.string(forKey: "config:auth:apiToken") else {
                return nil
            }
            return ApiToken(rawValue: token)
        }
        set {
            guard newValue?.rawValue != config.string(forKey: "config:auth:apiToken") else {
                Logger.shared.info("New API token value is identical to the previous")
                return
            }
            config.set(newValue?.rawValue, forKey: "config:auth:apiToken")
        }
    }
    var updateInterval: Int {
        get {
            let configUpdateInterval = config.integer(forKey: "config:run:updateInterval")
            guard configUpdateInterval != 0 else {
                return 1800
            }
            return configUpdateInterval
        }
        set {
            guard newValue != config.integer(forKey: "config:run:updateInterval") else {
                Logger.shared.info("New update interval is identical to the previous")
                return
            }
            config.set(newValue, forKey: "config:run:updateInterval")
            Logger.shared.info("Update interval was set to \(updateInterval)")
        }
    }
    
    var ip: DNSContent? = nil
    var records: [DNSRecord]
    private (set) var zones: [Zone]? = nil

    private let config: Config
    
    init(config: Config) {

        self.config = config

        // Load records
        if let rawRecords = config.array(forKey: "config:records:records") as? [Data] {
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
