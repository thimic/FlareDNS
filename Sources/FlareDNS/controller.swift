//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import CoreFoundation
import Foundation


struct FlareDNSController {
    
    static let shared = FlareDNSController()
    
    func run() {
        CFRunLoopRun()
    }
    
}
