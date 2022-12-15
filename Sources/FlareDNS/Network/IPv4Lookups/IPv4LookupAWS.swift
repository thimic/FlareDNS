//
//  IPv4LookupAWS.swift
//  
//
//  Created by Michael Thingnes on 12/12/22.
//

import Foundation


struct IPv4LookupAWS: IPv4Lookupable {

    let name = "Amazon AWS"
    let endpoint = URL(string: "https://checkip.amazonaws.com")!

}
