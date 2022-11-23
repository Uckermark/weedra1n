//
//  main.swift
//  PogoHelper
//
//  Created by Amy While on 12/09/2022.
//

import Foundation
import ArgumentParser
import SWCompression

struct Strap: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "The path to the .tar file you want to strap with")
    var input: String?
    
    @Flag(name: .shortAndLong, help: "Remove the bootstrap")
    var remove: Bool = false
    
    @Flag(name: .shortAndLong, help: "Download latest build")
    var update: Bool = false
    
    @Flag(name: .shortAndLong, help: "Extract ipa from zip")
    var extract: Bool = false
    
    @Flag(name: .shortAndLong, help: "Remove the custom documents directory")
    var clean: Bool = false
    
    @Flag(name: .long, help: "Download latest build from dev branch")
    var dev: Bool = false
    
    mutating func run() throws {
        NSLog("[weedInstaller] Spawned!")
        guard getuid() == 0 else { fatalError() }

        if let input = input {
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
                                NSLog("[POGO] \(entry.info.linkName) at \(linkName) to \(path)")
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
            
        } else if update {
            if !FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/") {
                let path = URL(string: "file:///var/mobile/Documents/weedra1n")!
                do {
                    try FileManager().createDirectory(at: path, withIntermediateDirectories: false)
                } catch {
                    NSLog("Could not create working directory: \(error.localizedDescription)")
                }
            }
            let url: URL
            if dev {
                url = URL(string: "https://nightly.link/Uckermark/weedra1n/workflows/devbuild/dev/weedra1n.zip")!
            } else {
                url = URL(string:
"https://nightly.link/Uckermark/weedra1n/workflows/build/main/weedra1n.zip")!
            }
            loadFileSync(url: url) { (path, error) in
                NSLog("Downloaded to path \(path!)")
            }
        } else if extract {
            unzip(file: "weedra1n.zip")
        } else if clean {
            let docPath = "/var/mobile/Documents/weedra1n/"
            let updateFiles = ["\(docPath)weedra1n.ipa", "\(docPath)weedra1n.zip"]
            for file in updateFiles {
                try? FileManager().removeItem(atPath: file)
            }
        }
    }
}

Strap.main()
