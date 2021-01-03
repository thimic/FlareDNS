//
//  File.swift
//  
//
//  Created by Michael Thingnes on 2/01/21.
//

import CoreFoundation
import Foundation
import Logging


struct FlareDNSController {
    
    static let shared = FlareDNSController()
    
    func run() {
        CFRunLoopRun()
    }
    
    func check(completion: @escaping (Result<String, Error>) -> Void) {
        var zoneNames: Set<String> = []
        for record in FlareDNSModel.shared.records {
            zoneNames.insert(record.zone.name)
        }
        if zoneNames.isEmpty {
            completion(Result.failure(FlareDNSError("No records have been added to the configuration")))
            Logger.shared.warning("No records have been added to the configuration")
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
                        FlareDNSModel.shared.zones = zones
                        completion(Result.success("Successfully fetched data for zones"))
                    }
                case .failure(let error):
                    completion(Result.failure(error))
                }
                DispatchQueue.main.async {
                    CFRunLoopStop(RunLoop.current.getCFRunLoop())
                }
            }
        )
        
//        for zoneName in zoneNames {
//            CloudFlareAPI.shared.listDNSRecords(
//                zone: zoneName,
//                completion: { result in
//                    switch result {
//                    case .success(let zones):
//                        let resultZoneNames = zones.map({ (zone: Zone) -> String in
//                            return zone.name
//                        })
//                        if zoneNames.sorted() != resultZoneNames.sorted() {
//                            completion(Result.failure(
//                                FlareDNSError(
//                                    "Expected data for zone(s) [\(zoneNames.sorted().joined(separator: ", "))], " +
//                                    "but only received data for zone(s) [\(resultZoneNames.sorted().joined(separator: ", "))]"
//                                )
//                            ))
//                        } else {
//                            completion(Result.success("Successfully fetched data for zones"))
//                        }
//                    case .failure(let error):
//                        completion(Result.failure(error))
//                    }
//                    DispatchQueue.main.async {
//                        CFRunLoopStop(RunLoop.current.getCFRunLoop())
//                    }
//                }
//            )
//        }
        
        CFRunLoopRun()
    }
    
}
