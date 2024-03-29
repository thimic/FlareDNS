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
    
    struct Auth: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure Cloudflare authentication",
            subcommands: [Set.self, Get.self, Remove.self]
        )
                
    }

    struct Records: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure records",
            subcommands: [Add.self, List.self, Remove.self, ListAll.self, RemoveAll.self]
        )
        
    }
    
    struct Run: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Configure run options",
            subcommands: [UpdateInterval.self, ForceUpdate.self]
        )
        
    }
    
    struct Check: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(
            abstract: "Check configuration. Connects to Cloudflare with configured credentials and checks that the records are available and editable.",
            subcommands: [Config.self, IP.self]
        )
        
    }
    
}
