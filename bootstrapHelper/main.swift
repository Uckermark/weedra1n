//
//  bootstrapHelper.swift
//  bootstrapHelper
//
//  Created by Leonard Lausen on 22.11.22.
//

import ArgumentParser
import Foundation

struct Cache: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "app bundle path")
    var path: String
    
    @Flag(name: .shortAndLong, help: "load from cache")
    var load = false
    
    mutating func run() throws {
        guard getuid() == 0 else { fatalError()}
        
        if load {
            guard FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/bootstrap.tar") else {
                NSLog("Could not find tar in Cache")
                return
            }
            let tar = "/var/mobile/Documents/weedra1n/bootstrap.tar"
            do {
                try FileManager().copyItem(atPath: tar, toPath: path)
            } catch {
                NSLog("Could not fetch from cache: \(error.localizedDescription)")
            }
        } else {
            let tar = "/var/mobile/Documents/weedra1n/bootstrap.tar"
            do {
                try FileManager().copyItem(atPath: path, toPath: tar)
            } catch {
                NSLog("Caching failed: \(error.localizedDescription)")
            }
        }
    }
}

Cache.main()
