//
//  File.swift
//  
//
//  Created by Michael Thingnes on 3/01/21.
//

import CoreFoundation
import Foundation
import Logging


extension FlareDNSModel {
    
//    mutating func loadZones(completion: @escaping (Result<[Zone], Error>) -> Void) {
//        _loadZones(completion: { result in
//            switch result {
//            case .success(let zones):
//                self.zones = zones
//                completion(Result.success(zones))
//            case .failure(let error):
//                completion(Result.failure(error))
//            }
//        })
//    }
    
    private func _loadZones(completion: @escaping (Result<[Zone], Error>) -> Void) {
        var zoneNames: Set<String> = []
        for record in records {
            zoneNames.insert(record.zone.name)
        }
        if zoneNames.isEmpty {
            completion(Result.failure(FlareDNSError("No records have been added to the configuration")))
            return
        }
        CloudFlareAPI.shared.listZones(
            zoneNames: zoneNames.sorted(),
            completion: { result in
                switch result {
                case .success(let zones):
                    let resultZoneNames = zones.map({ (zone: Zone) -> String in
                        return zone.name
                    })
                    if zoneNames.sorted() != resultZoneNames.sorted() {
                        completion(Result.failure(
                            FlareDNSError(
                                "Expected data for zone(s) [\(zoneNames.sorted().joined(separator: ", "))], " +
                                "but only received data for zone(s) [\(resultZoneNames.sorted().joined(separator: ", "))]"
                            )
                        ))
                    } else {
                        completion(Result.success(zones))
                    }
                case .failure(let error):
                    completion(Result.failure(error))
                }
                DispatchQueue.main.async {
                    CFRunLoopStop(RunLoop.current.getCFRunLoop())
                }
            }
        )
        CFRunLoopRun()
    }
    
}
