//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import ArgumentParser
import ColorizeSwift
import Foundation
import Logging

extension FlareDNSCommand.Configure.Records {
    
    struct Add: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Add DNS record to configuration")
        
        @Argument(help: "Cloudflare Zone name") var zoneName: String
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        @Option(name: .shortAndLong, help: "DNS record type") var recordType: DNSRecord.Types
        @Option(name: .shortAndLong, help: "Time To Live in seconds") var ttl: Int = 1800
        @Flag(help: "Proxy traffic through CloudFlare") var proxied: Bool = false
        
        func run() {
            let record = DNSRecord(zoneName: zoneName, recordName: recordName, type: recordType, ttl: ttl, proxied: proxied)
            FlareDNSModel.shared.addRecord(record)
            print("Added record \(record.description)".green())
        }
        
    }
    
    struct List: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "List all DNS records from configuration")
        
        @Argument(help: "Cloudflare Zone name") var zoneName: String
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        @Flag(help: "Format output as json") var json: Bool = false

        func run() {
            
            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let record = FlareDNSModel.shared.getRecord(zoneName: zoneName, recordName: recordName)
                do {
                    let jsonData = try encoder.encode(record)
                    print(String(data:jsonData, encoding: .utf8)!)
                } catch {
                    print("null")
                }
                return
            }
            
            guard let record = FlareDNSModel.shared.getRecord(zoneName: zoneName, recordName: recordName) else {
                print("No records matching zone name \"\(zoneName)\" and record name \"\(recordName)\"".yellow())
                return
            }
            print("\(record)".cyan())
        }
        
    }
    
    struct Remove: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove named DNS record from configuration")
        
        @Argument(help: "Cloudflare Zone name") var zoneName: String
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        
        func run() {
            let result = FlareDNSModel.shared.removeRecord(zoneName: zoneName, recordName: recordName)
            switch result {
            case .success(let message):
                print("\(message)".green())
            case .failure(let error):
                print("\(error.message)".red())
            }
        }
        
    }
    
    struct RemoveAll: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove all DNS records from configuration")
                
        func run() {
            FlareDNSModel.shared.removeAllRecords()
            print("Removed all records".green())
        }
        
    }
    
    struct ListAll: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "List all DNS records from configuration")
        
        @Flag(help: "Format output as json") var json: Bool = false

        func run() {
            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                do {
                    let jsonData = try encoder.encode(FlareDNSModel.shared.records)
                    print(String(data:jsonData, encoding: .utf8)!)
                } catch {
                    print("[]")
                }
                return
            }
            if FlareDNSModel.shared.records.count <= 0 {
                print("No records".yellow())
                return
            }
            for record in FlareDNSModel.shared.records {
                print(record.description.cyan())
            }
        }
        
    }
    
}
