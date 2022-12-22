//
//  IPv4LookupIPEcho.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation


struct IPv4LookupIPEcho: IPv4Lookupable {

    let name = "IP Echo"
    let endpoint = URL(string: "http://ipecho.net/plain")!

}
