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


struct FlareDNSCommand: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "FlareDNS CLI", subcommands: [Run.self, Configure.self])
    
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
    
    struct Configure: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure FlareDNS before running",
            subcommands: [Auth.self, Records.self, Run.self]
        )
        
    }
    
}
