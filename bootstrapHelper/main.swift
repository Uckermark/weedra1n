//
//  bootstrapHelper.swift
//  bootstrapHelper
//
//  Created by Leonard Lausen on 22.11.22.
//

import Foundation
import ArgumentParser
import SWCompression

struct Cache: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "The path to the .tar file you want to strap with")
    var input: String?
    
    @Flag(name: .shortAndLong, help: "Remove the bootstrap")
    var remove: Bool = false
    
    @Flag(name: .shortAndLong, help: "Download bootstrap")
    var load = false
    
    mutating func run() throws {
        guard getuid() == 0 else { fatalError()}
        
        if load {
            let url = URL(string: "https://nightly.link/Uckermark/weedra1n/workflows/devbuild/helper/bootstrap.zip")!
            NSLog("Downloading bootstrap")
            loadFileSync(url: url) { (path, error) in
                NSLog("Downloaded bootstrap to \(path)")
            }
            unzip(file: "bootstrap.zip")
        } else if let input = input {
            NSLog("[weedInstaller] Attempting to install \(input)")
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[weedInstaller] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try autoreleasepool {
                    let data = try Data(contentsOf: URL(fileURLWithPath: input))
                    let container = try TarContainer.open(container: data)
                    NSLog("[weedInstaller] Opened Container")
                    for entry in container {
                        do {
                            var path = entry.info.name
                            if path.first == "." {
                                path.removeFirst()
                            }
                            if path == "/" || path == "/var" {
                                continue
                            }
                            path = path.replacingOccurrences(of: "/var/jb", with: dest)
                            switch entry.info.type {
                            case .symbolicLink:
                                var linkName = entry.info.linkName
                                if !linkName.contains("/") || linkName.contains("..") {
                                    var tmp = path.split(separator: "/").map { String($0) }
                                    tmp.removeLast()
                                    tmp.append(linkName)
                                    linkName = tmp.joined(separator: "/")
                                    if linkName.first != "/" {
                                        linkName = "/" + linkName
                                    }
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                } else {
                                    linkName = linkName.replacingOccurrences(of: "/var/jb", with: dest)
                                }
                                NSLog("[weedInstaller] \(entry.info.linkName) at \(linkName) to \(path)")
                                try FileManager.default.createSymbolicLink(atPath: path, withDestinationPath: linkName)
                            case .directory:
                                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
                            case .regular:
                                guard let data = entry.data else { continue }
                                try data.write(to: URL(fileURLWithPath: path))
                            default:
                                NSLog("[weedInstaller] Unknown Action for \(entry.info.type)")
                            }
                            var attributes = [FileAttributeKey: Any]()
                            attributes[.posixPermissions] = entry.info.permissions?.rawValue
                            attributes[.ownerAccountName] = entry.info.ownerUserName
                            var ownerGroupName = entry.info.ownerGroupName
                            if ownerGroupName == "staff" && entry.info.ownerUserName == "root" {
                                ownerGroupName = "wheel"
                            }
                            attributes[.groupOwnerAccountName] = ownerGroupName
                            do {
                                try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
                            } catch {
                                continue
                            }
                        } catch {
                            NSLog("[weedInstaller] error \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                NSLog("[weedInstaller] Failed with error \(error.localizedDescription)")
                return
            }
            NSLog("[weedInstaller] Strapped to \(dest)")
            do {
                if !FileManager.default.fileExists(atPath: "/var/jb") {
                    try FileManager.default.createSymbolicLink(atPath: "/var/jb", withDestinationPath: dest)
                }
            } catch {
                NSLog("[weedInstaller] Failed to make link")
                fatalError()
            }
            NSLog("[weedInstaller] Linked to /var/jb")
            var attributes = [FileAttributeKey: Any]()
            attributes[.posixPermissions] = 0o755
            attributes[.ownerAccountName] = "mobile"
            attributes[.groupOwnerAccountName] = "mobile"
            do {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: "/var/jb/var/mobile")
            } catch {
                NSLog("[weedInstaller] thats wild")
            }
        } else if remove {
            let active = "/private/preboot/active"
            let uuid: String
            do {
                uuid = try String(contentsOf: URL(fileURLWithPath: active), encoding: .utf8)
            } catch {
                NSLog("[weedInstaller] Could not find active directory")
                fatalError()
            }
            let dest = "/private/preboot/\(uuid)/procursus"
            do {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: dest))
                try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb"))
            } catch {
                NSLog("[weedInstaller] Failed with error \(error.localizedDescription)")
            }
            
        }
    }
}

Cache.main()
