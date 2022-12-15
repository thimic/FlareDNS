//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import Foundation


import ArgumentParser
import ColorizeSwift
import Foundation
import Logging


extension FlareDNSCommand.Configure.Run {
        
    struct UpdateInterval: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Interval between each check for IP change")
        
        @Argument(help: "Update interval in seconds") var updateInterval: Int
        
        func run() throws {
            Config().set(updateInterval, forKey: "config:run:updateInterval")
            print("Update interval was set to \(updateInterval)".green())
            Logger.shared.info("Update interval was set to \(updateInterval)")
        }
    }
    
    struct ForceUpdate: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Force update the server record, even when no change is detected")
        
        @Argument(help: "Enable force update") var updateInterval: Bool
        
        func run() throws {
            Config().set(updateInterval, forKey: "config:run:forceUpdate")
            print("Update interval was set to \(updateInterval)".green())
            Logger.shared.info("Update interval was set to \(updateInterval)")
        }
    }
}
