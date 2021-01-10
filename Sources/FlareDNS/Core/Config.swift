//
//  File.swift
//  
//
//  Created by Michael Thingnes on 28/12/20.
//

import Foundation
import Logging


class Config {
        
    private var configDict: [String : Any]
    private var url: URL
    
    init() {
        
        let configFileName = "FlareDNS.plist"
        
        func getURL() -> URL {
            let env = ProcessInfo.processInfo.environment
            let configDirs = ["FLAREDNS_CONFIG", "XDG_CONFIG_DIR"]
            var urls: [URL] = []
            for configDir in configDirs {
                guard let configDirPath = env[configDir] else { continue }
                var configURL = URL(fileURLWithPath: configDirPath)
                configURL.appendPathComponent(configFileName)
                if FileManager.default.fileExists(atPath: configURL.path) {
                    return configURL
                }
                urls.append(configURL)
            }
            #if os(macOS)
            if let homeDir = env["HOME"] {
                let homeURL = URL(fileURLWithPath: homeDir)
                let prefsURL = homeURL
                                .appendingPathComponent("Library")
                                .appendingPathComponent("Preferences")
                                .appendingPathComponent(configFileName)
                if FileManager.default.fileExists(atPath: prefsURL.path) {
                    print("prefsURL exists! \(prefsURL)")
                    return prefsURL
                }
                urls.append(prefsURL)
            }
            #endif
            
            for configURL in urls {
                do {
                    try FileManager.default.createDirectory(
                        at: configURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    return configURL
                } catch {
                    Logger.shared.error("Unable to create directory: \(configURL.deletingLastPathComponent().path)")
                    continue
                }
            }
            
            let globalURL = URL(fileURLWithPath: "/usr/local/etc").appendingPathComponent(configFileName)
            return globalURL
        }
                
        func decode(_ url: URL) -> [String : Any] {
            guard let data = try? Data(contentsOf: url) else { return [:] }
            guard let plistData = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String : Any] else { return [:] }
            return plistData
        }

        self.url = getURL()
        self.configDict = decode(self.url)
        
        Logger.shared.info("Config path: \(self.url.path)")
    }
    
    private func encode(onError: @escaping (Error) -> Void = {_ in}) {
        var plistData: Data? = nil
        do {
            plistData = try PropertyListSerialization.data(fromPropertyList: configDict, format: .xml, options: .zero)
        } catch {
            onError(error)
            return
        }

        if let plistData = plistData {
            do {
                try plistData.write(to: url)
            } catch {
                onError(error)
                return
            }
        } else {
            onError(FlareDNSError("Failed to encode and store config data"))
            return
        }
    }
    
    /**
     -dictionaryRepresentation returns a composite snapshot of the values in the receiver's search list, such that [[receiver dictionaryRepresentation] objectForKey:x] will return the same thing as [receiver objectForKey:x].
     */
    func dictionaryRepresentation() -> [String : Any] { configDict }
    
    /**
     -objectForKey: will search the receiver's search list for a default with the key 'key' and return it. If another process has changed defaults in the search list, NSUserDefaults will automatically update to the latest values. If the key in question has been marked as ubiquitous via a Defaults Configuration File, the latest value may not be immediately available, and the registered value will be returned instead.
     */
    func object(forKey key: String) -> Any? {
        configDict[key]
    }
    
    /**
     -setObject:forKey: immediately stores a value (or removes the value if nil is passed as the value)
     */
    func set(_ value: Any?, forKey key: String) {
        if value == nil {
            removeObject(forKey: key)
            return
        }
        configDict[key] = value
        encode()
    }
    
    /**
     -setObject:forKey: immediately stores a value (or removes the value if nil is passed as the value), then asynchronously stores the value persistently, where it is made available to other processes.
     */
    func set(_ value: Any?, forKey key: String, onError: @escaping (Error) -> Void) {
        if value == nil {
            removeObject(forKey: key, onError: onError)
            return
        }
        configDict[key] = value
        DispatchQueue.global(qos: .background).async {
            self.encode(onError: onError)
        }
    }
    
    /// -removeObjectForKey: is equivalent to -[... setObject:nil forKey:defaultName]
    func removeObject(forKey key: String) {
        configDict.removeValue(forKey: key)
        encode()
    }
    
    /// -asyncRemoveObjectForKey: is equivalent to -[... asyncSetObject:nil forKey:defaultName]
    func removeObject(forKey key: String, onError: @escaping (Error) -> Void) {
        configDict.removeValue(forKey: key)
        DispatchQueue.global(qos: .background).async {
            self.encode(onError: onError)
        }
    }
    
    func string(forKey key: String) -> String? {
        configDict[key] as? String
    }
    
    /// -arrayForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray.
    func array(forKey key: String) -> [Any]? {
        configDict[key] as? [Any]
    }

    /// -dictionaryForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSDictionary.
    func dictionary(forKey key: String) -> [String : Any]? {
        configDict[key] as? [String : Any]
    }
    
    /// -dataForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSData.
    func data(forKey key: String) -> Data? {
        configDict[key] as? Data
    }
    
    /// -stringForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray<NSString *>. Note that unlike -stringForKey:, NSNumbers are not converted to NSStrings.
    func stringArray(forKey key: String) -> [String]? {
        configDict[key] as? [String]
    }
    
    /**
     -integerForKey: is equivalent to -objectForKey:, except that it converts the returned value to an NSInteger. If the value is an NSNumber, the result of -integerValue will be returned. If the value is an NSString, it will be converted to NSInteger if possible. If the value is a boolean, it will be converted to either 1 for YES or 0 for NO. If the value is absent or can't be converted to an integer, 0 will be returned.
     */
    func integer(forKey key: String) -> Int {
        configDict[key] as? Int ?? 0
    }
    
    /// -floatForKey: is similar to -integerForKey:, except that it returns a float, and boolean values will not be converted.
    func float(forKey key: String) -> Float {
        configDict[key] as? Float ?? 0.0
    }

    /// -doubleForKey: is similar to -integerForKey:, except that it returns a double, and boolean values will not be converted.
    func double(forKey key: String) -> Double {
        configDict[key] as? Double ?? 0.0
    }
    
    /**
     -boolForKey: is equivalent to -objectForKey:, except that it converts the returned value to a BOOL. If the value is an NSNumber, NO will be returned if the value is 0, YES otherwise. If the value is an NSString, values of "YES" or "1" will return YES, and values of "NO", "0", or any other string will return NO. If the value is absent or can't be converted to a BOOL, NO will be returned.
     */
    func bool(forKey key: String) -> Bool {
        configDict[key] as? Bool ?? false
    }
    
}


extension Config {

    static var shared = Config()

}
