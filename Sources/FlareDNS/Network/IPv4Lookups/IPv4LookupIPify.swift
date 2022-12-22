//
//  IPv4LookupIPify.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation


struct IPv4LookupIPify: IPv4Lookupable {

    let name = "IPify"
    let endpoint = URL(string: "https://api.ipify.org")!

}
