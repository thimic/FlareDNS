//
//  File.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import Foundation


struct FlareDNSError: LocalizedError {
    
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var errorDescription: String? {
        return message
    }
}
