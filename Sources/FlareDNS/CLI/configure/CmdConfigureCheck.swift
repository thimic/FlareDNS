//
//  File.swift
//  
//
//  Created by Michael Thingnes on 4/01/21.
//

import ArgumentParser
import CoreFoundation
import Foundation


extension FlareDNSCommand.Configure.Check {
    
    struct Config: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Check configuration. Connects to Cloudflare with configured credentials and checks that the records are available and editable.")
                
        func run() throws {
            guard let controller = FlareDNSController() else {
                print("Unable to start checks: No API token was set.".red())
                return
            }
            print("Starting checks".blue())

            controller.check()
                .done { message in
                    print(message.green())
                }
                .catch { error in
                    print("\(error)".red())
                }
                .finally {
                    DispatchQueue.main.async {
                        CFRunLoopStop(RunLoop.current.getCFRunLoop())
                    }
                }
            CFRunLoopRun()
        }
        
    }
    
    struct IP: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Display current IP address")
                
        func run() throws {
            IPv4LookupAPI.shared.getIP()
                .done { ip in
                    print(ip.rawValue.cyan())
                }
                .catch { error in
                    print("Unable to obtain IP address: \(error)")
                }
                .finally {
                    DispatchQueue.main.async {
                        CFRunLoopStop(RunLoop.current.getCFRunLoop())
                    }
                }
            CFRunLoopRun()
        }
        
    }
    
}
