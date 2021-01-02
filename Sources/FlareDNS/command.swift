//
//  File.swift
//  
//
//  Created by Michael Thingnes on 26/12/20.
//

import ArgumentParser
import ColorizeSwift
import CoreFoundation
import Foundation
import Logging


struct FlareDNSCommand: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "FlareDNS CLI", subcommands: [Run.self, Configure.self])
    
}

extension FlareDNSCommand {

    struct Configure: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure FlareDNS before running",
            subcommands: [Auth.self, Records.self, Run.self]
        )
        
    }
    
    struct Run: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Run DNS updater once configured"
        )
        
        @Option(help: "Interval between each check for IP change") var updateInterval: Int = 3600
        @Flag(help: "Force update the server record, even when no change is detected") var forceUpdate: Bool = false
        
        func run() throws {
            Logger.shared.info("Starting FlareDNS...")
        }
        
    }
}

extension FlareDNSCommand.Configure {
    
    struct Auth: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure Cloudflare authentication"
        )
        
        @Option(help: "Cloudflare API token") var token: String
        
        func run() throws {
            Config.shared.set(token, forKey: "apiToken", completion: {
                CFRunLoopStop(RunLoop.main.getCFRunLoop())
            })
            Logger.shared.info("\("API token was set".green())")
        }
        
    }

    struct Records: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure records",
            subcommands: [Add.self, List.self, Remove.self, ListAll.self, ClearAll.self]
        )
        
    }
    
    struct Run: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure run options"
        )
        
        @Option(help: "Interval between each check for IP change") var updateInterval: Int = 3600
        @Flag(help: "Force update the server record, even when no change is detected") var forceUpdate: Bool = false
        
    }
    
}

extension FlareDNSCommand.Configure.Records {
    
    struct Add: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Add DNS record to configuration")
        
        @Argument(help: "DNS record name; use @ for root") var name: String
        @Option(name: .shortAndLong, help: "DNS record type") var recordType: DNSRecord.Types
        @Option(name: .shortAndLong, help: "Time To Live in seconds") var ttl: Int = 1800
        @Flag(help: "Proxy traffic through CloudFlare") var proxied: Bool = false
        
        func run() {
            let encoder = PropertyListEncoder()
            let record = DNSRecord(name: name, type: recordType, ttl: ttl, proxied: proxied)
            
            let decoder = PropertyListDecoder()
            var storedRecords = Config.shared.array(forKey: "records") as? [Data] ?? [Data]()
            var records: [DNSRecord] = []
            for storedRecord in storedRecords {
                if let record = try? decoder.decode(DNSRecord.self, from: storedRecord) {
                    records.append(record)
                }
            }
            let filteredRecords = records.filter { (record) -> Bool in
                record.name == name
            }
            
            if filteredRecords.count > 0 {
                let oldRecord = filteredRecords.first!
                let index = records.firstIndex(of: oldRecord)!
                storedRecords.remove(at: index)
            }
            
            guard let encodedRecord = try? encoder.encode(record) else {
                Logger.shared.error("Unable to add record \(record)")
                return
            }
            print("Added: \(record)")
            
            storedRecords.append(encodedRecord)
            Config.shared.set(storedRecords, forKey: "records", completion: {
                CFRunLoopStop(RunLoop.main.getCFRunLoop())
            })
        }
        
    }
    
    struct List: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "List all DNS records from configuration")
        
        @Argument(help: "DNS record name; use @ for root") var name: String
        @Flag(help: "Format output as json") var json: Bool = false

        func run() {
            let decoder = PropertyListDecoder()
            let storedRecords = Config.shared.array(forKey: "records")
            var records: [DNSRecord] = []
            for storedRecord in storedRecords as? [Data] ?? [Data]() {
                if let record = try? decoder.decode(DNSRecord.self, from: storedRecord) {
                    records.append(record)
                }
            }
            let filteredRecords = records.filter { (record) -> Bool in
                record.name == name
            }
            print(filteredRecords.first ?? "Found no record with name \"\(name)\"")
            DispatchQueue.main.async {
                CFRunLoopStop(RunLoop.main.getCFRunLoop())
            }
        }
        
    }
    
    struct Remove: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove named DNS record from configuration")
        
        @Argument(help: "DNS record name; use @ for root") var name: String
        
        func run() {
            print("Removed: \"\(name)\"")
        }
        
    }
    
    struct ClearAll: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove all DNS records from configuration")
                
        func run() {
            print("Cleared all records")
        }
        
    }
    
    struct ListAll: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "List all DNS records from configuration")
        
        @Flag(help: "Format output as json") var json: Bool = false

        func run() {
            let decoder = PropertyListDecoder()
            let storedRecords = Config.shared.array(forKey: "records")
            for storedRecord in storedRecords as? [Data] ?? [Data]() {
                if let record = try? decoder.decode(DNSRecord.self, from: storedRecord) {
                    print(record.name)
                }
            }
            DispatchQueue.main.async {
                CFRunLoopStop(RunLoop.main.getCFRunLoop())
            }
        }
        
    }
    
}
