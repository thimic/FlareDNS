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
    
    struct Table {
        
        struct Column {
            let name: String
            let width: Int
        }
        
        private struct Row {
            let data: [String]
        }
        
        private var columns: [Column]
        private var rows: [Row] = []
        
        init(_ columns: Column...) {
            self.columns = columns
        }
        
        mutating func addRow(_ rowData: String...) {
            if rowData.count != columns.count {
                Logger.shared.error("Unable to add a \(rowData.count) column row to a \(columns.count) column table")
                return
            }
            rows.append(Row(data: rowData))
        }
        
        var header: String {
            let strings = columns.map { (column: Column) -> String in
                return column.name.padding(toLength: column.width, withPad: " ", startingAt: 0)
            }
            return strings.joined()
        }
        
        var body: String {
            var rows_: [String] = []
            for row in rows {
                var row_: [String] = []
                for (index, value) in row.data.enumerated() {
                    let column = columns[index]
                    row_.append(value.padding(toLength: column.width, withPad: " ", startingAt: 0))
                }
                rows_.append(row_.joined())
            }
            return rows_.joined(separator: "\n")
        }
        
        func print() {
            Swift.print(header.bold())
            Swift.print(body.cyan())
        }
    }
    
    private static func printRecords(_ records: [DNSRecord]) {
        
        var table = Table(
            .init(name: "Type", width: 10),
            .init(name: "Name", width: 25),
            .init(name: "Zone", width: 20),
            .init(name: "TTL", width: 10),
            .init(name: "Priority", width: 15),
            .init(name: "Proxied", width: 10)
        )
        
        for record in records {
            table.addRow(
                record.type.rawValue,
                record.name,
                record.zone.name,
                record.ttl == 1 ? "auto" : "\(record.ttl)",
                "\(record.priority)",
                "\(record.proxied)"
            )
        }
        table.print()
    }
    
    private static func resolveRecordName(zoneName: String, recordName: String) -> String {
        var name = recordName
        if !name.hasSuffix(zoneName) {
            if name == "@" {
                name = zoneName
            } else {
                name = "\(recordName).\(zoneName)"
            }
        }
        return name
    }
    
    struct Add: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Add DNS record to configuration")
        
        @Argument(help: "Cloudflare Zone name") var zoneName: String
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        @Option(name: .shortAndLong, help: "DNS record type") var recordType: DNSRecordTypes
        @Option(name: .shortAndLong, help: "Time To Live in seconds: 1 for auto, otherwise 120 to 2,147,483,647 seconds") var ttl: Int = 1
        @Flag(help: "Proxy traffic through CloudFlare") var proxied: Bool = false
        
        func run() {
            guard ttl == 1 || (120...2147483647).contains(ttl) else {
                print("TTL must be between 120 and 2,147,483,647 seconds, or 1 for Automatic.".yellow())
                return
            }
            let name = resolveRecordName(zoneName: zoneName, recordName: recordName)
            let record = DNSRecord(zoneName: zoneName, recordName: name, type: recordType, ttl: ttl, proxied: proxied)
            FlareDNSModel.shared.addRecord(record)
            printRecords([record])
        }
        
    }
    
    struct List: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "List all DNS records from configuration")
        
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        @Flag(help: "Format output as json") var json: Bool = false

        func run() {
                        
            if json {
                let encoder = JSONEncoder()
                if #available(OSX 10.13, *) {
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                } else {
                    encoder.outputFormatting = [.prettyPrinted]
                }
                let record = FlareDNSModel.shared.getRecord(recordName: recordName)
                do {
                    let jsonData = try encoder.encode(record)
                    print(String(data:jsonData, encoding: .utf8)!)
                } catch {
                    print("null")
                }
                return
            }
            
            guard let record = FlareDNSModel.shared.getRecord(recordName: recordName) else {
                print("No records matching record name \"\(recordName)\"".yellow())
                return
            }
            printRecords([record])
        }
        
    }
    
    struct Remove: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove named DNS record from configuration")
        
        @Argument(help: "DNS record name; use @ for root") var recordName: String
        
        func run() {
            let result = FlareDNSModel.shared.removeRecord(recordName: recordName)
            switch result {
            case .success(let message):
                print("\(message)".green())
            case .failure(let error):
                print("\(error.localizedDescription)".red())
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
                if #available(OSX 10.13, *) {
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                } else {
                    encoder.outputFormatting = [.prettyPrinted]
                }
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
            printRecords(FlareDNSModel.shared.records)
        }
        
    }
    
}
