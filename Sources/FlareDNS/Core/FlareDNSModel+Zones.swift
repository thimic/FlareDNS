//
//  FlareDNSModel+Zones.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import Foundation
import Logging


extension FlareDNSModel {
    var configZones: [Zone] {
        var zones: Set<Zone> = []
        for record in records {
            zones.insert(record.zone)
        }
        return zones.sorted { (first, second) -> Bool in
            first.name < second.name
        }
    }
    
    var configZoneNames: [String] {
        configZones.map { zone in zone.name }
    }
    
}
