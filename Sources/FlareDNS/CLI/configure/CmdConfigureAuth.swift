//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import ArgumentParser
import ColorizeSwift
import Foundation


extension FlareDNSCommand.Configure.Auth {
        
    struct Set: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Set Cloudflare API token")
        
        @Argument(help: "Cloudflare API token") var token: String
        
        func run() throws {
            let model = FlareDNSModel(config: Config())
            model.apiToken = ApiToken(rawValue: token)
            print("API token was set".green())
        }
        
    }
    
    struct Get: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Get Cloudflare API token")
                
        func run() throws {
            let model = FlareDNSModel(config: Config())
            guard let token = model.apiToken else {
                print("No API token found".red())
                return
            }
            print(token.rawValue.cyan())
        }
        
    }
    
    struct Remove: AsyncParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove Cloudflare API token")
                
        func run() throws {
            let model = FlareDNSModel(config: Config())
            if model.apiToken == nil {
                print("No API token was set".yellow())
                return
            }
            model.apiToken = nil
            print("API token was removed".green())
        }
    }
    
}
