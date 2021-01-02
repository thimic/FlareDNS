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
        
    struct Set: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Set Cloudflare API token")
        
        @Argument(help: "Cloudflare API token") var token: String
        
        func run() throws {
            FlareDNSModel.shared.apiToken = ApiToken(rawValue: token)
            print("API token was set".green())
        }
        
    }
    
    struct Get: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Get Cloudflare API token")
                
        func run() throws {
            guard let token = FlareDNSModel.shared.apiToken else {
                print("No API token found".red())
                return
            }
            print(token.rawValue.cyan())
        }
        
    }
    
    struct Remove: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Remove Cloudflare API token")
                
        func run() throws {
            if FlareDNSModel.shared.apiToken == nil {
                print("No API token was set".yellow())
                return
            }
            FlareDNSModel.shared.apiToken = nil
            print("API token was removed".green())
        }
    }
    
}
