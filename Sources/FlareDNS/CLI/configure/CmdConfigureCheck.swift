//
//  File.swift
//  
//
//  Created by Michael Thingnes on 4/01/21.
//

import ArgumentParser
import Foundation

extension FlareDNSCommand.Configure.Check {
    
    struct Config: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Check configuration. Connects to Cloudflare with configured credentials and checks that the records are available and editable.")

        func run() async throws {
            let model = FlareDNSModel(config: FlareDNS.Config())
            var controller: FlareDNSController
            do {
                controller = try FlareDNSController(model: model, ipV4Lookup: IPv4LookupAPI())
            } catch {
                print("Unable to start checks: \(error.localizedDescription).".red())
                return
            }
            print("Starting checks".blue())

            let message = try await controller.check()
            print(message.green())
        }
        
    }
    
    struct IP: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Display current IP address")

        func run() async throws {
            let ip = try await IPv4LookupAPI().getIP()
            print(ip.rawValue.cyan())
        }
        
    }
    
}
