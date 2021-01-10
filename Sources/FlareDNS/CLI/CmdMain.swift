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
import PromiseKit


struct FlareDNSCommand: ParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "FlareDNS CLI", subcommands: [Run.self, Configure.self])
    
    struct Run: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Run DNS updater once configured"
        )
        
        @Option(help: "Interval between each check for IP change") var updateInterval: Int = 3600
        @Flag(help: "Force update the server record, even when no change is detected") var forceUpdate: Bool = false
        
        @available(OSX 10.12, *)
        private func start(_ controller: FlareDNSController) {
            firstly {
                controller.run()
            }
            .done { messages in
                for message in messages {
                    Logger.shared.info("\(message.cyan())")
                }
            }
            .catch { error in
                Logger.shared.error("\("\(error)".red())")
            }
            .finally {
                Logger.shared.info("---")
            }
        }
        
        func run() throws {
            guard #available(OSX 10.12, *) else {
                print("FlareDNS requires macOS 10.12 or newer to run")
                return
            }
            guard let controller = FlareDNSController() else {
                print("Unable to start FlareDNS: No API token was set.".yellow())
                return
            }
            guard !controller.model.records.isEmpty else {
                print("FlareDNS has not been configured with any DNS records. Aborting.".yellow())
                return
            }
            Logger.shared.info("\("Starting FlareDNS".bold())")
            Logger.shared.info("---")

            // TODO: Move timer to controller?
            start(controller)
            _ = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(FlareDNSModel.shared.updateInterval),
                repeats: true
            ) { _ in
                start(controller)
            }

            RunLoop.main.run()
        }
        
    }
    
    struct Configure: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure FlareDNS before running",
            subcommands: [Auth.self, Records.self, Run.self, Check.self]
        )
        
    }
    
}
