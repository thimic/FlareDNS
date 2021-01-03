//
//  File.swift
//  
//
//  Created by Michael Thingnes on 28/12/20.
//

import Logging


extension Logger {
    static var shared: Logger {
        var logger = Logger(label: "FlareDNS")
        logger.logLevel = .warning
        return logger
    }
}
