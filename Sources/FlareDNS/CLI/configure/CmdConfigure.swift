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


extension FlareDNSCommand.Configure {
    
    struct Auth: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure Cloudflare authentication",
            subcommands: [Set.self, Get.self, Remove.self]
        )
                
    }

    struct Records: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure records",
            subcommands: [Add.self, List.self, Remove.self, ListAll.self, RemoveAll.self]
        )
        
    }
    
    struct Run: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure run options",
            subcommands: [UpdateInterval.self, ForceUpdate.self]
        )
        
    }
    
    struct Check: ParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Check configuration. Connects to Cloudflare with configured credentials and checks that the records are available and editable."
        )
        
        func run() throws {
            print("Starting checks".blue())
            FlareDNSController.shared.check(completion: { result in
                switch result {
                case .success(let message):
                    print(message.green())
                case .failure(let error):
                    print(error.localizedDescription.red())
                }
            })
        }
        
    }
    
}
