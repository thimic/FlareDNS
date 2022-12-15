//
//  IPv4LookupIPInfo.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation


struct IPv4LookupIPInfo: IPv4Lookupable {

    let name = "IP Info"
    let endpoint = URL(string: "http://ipinfo.io/ip")!

}
