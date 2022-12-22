//
//  Logger+FlareDNS.swift
//  
//
//  Created by Michael Thingnes on 28/12/20.
//

import Logging


extension Logger {

    static var shared: Logger {
        var logger = Logger(label: "FlareDNS")
        #if DEBUG
        logger.logLevel = .debug
        #else
        logger.logLevel = .info
        #endif
        return logger
    }

}
