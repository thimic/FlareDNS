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


@main
struct FlareDNSCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "FlareDNS CLI", subcommands: [Run.self, Configure.self])

    struct Run: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Run DNS updater once configured"
        )
        
        @Option(help: "Interval between each check for IP change") var updateInterval: Int = 3600
        @Flag(help: "Force update the server record, even when no change is detected") var forceUpdate: Bool = false

        func run() async throws {
            var controller: FlareDNSController
            do {
                controller = try FlareDNSController(model: FlareDNSModel(config: Config()), ipV4Lookup: IPv4LookupAPI())
            } catch {
                print("Unable to start FlareDNS: \(error.localizedDescription)".yellow())
                return
            }
            guard !controller.model.records.isEmpty else {
                print("FlareDNS has not been configured with any DNS records. Aborting.".yellow())
                return
            }
            Logger.shared.info("\("Starting FlareDNS".bold())")
            Logger.shared.info("---")

            repeat {
                try await start(controller)
                try await Task.sleep(for: .seconds(controller.model.updateInterval))
            } while !Task.isCancelled
        }

        private func start(_ controller: FlareDNSController) async throws {
            do {
                for message in try await controller.run() {
                    Logger.shared.info("\(message.cyan())")
                }
            } catch {
                Logger.shared.error("\("\(error)".red())")
            }
            Logger.shared.info("---")
        }
        
    }
    
    struct Configure: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure FlareDNS before running",
            subcommands: [Auth.self, Records.self, Run.self, Check.self]
        )
        
    }
    
}
