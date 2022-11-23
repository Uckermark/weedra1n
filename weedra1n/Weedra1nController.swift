//
//  actionController.swift
//  weedra1n
//
//  Created by Uckermark on 16.10.22.
//

import Foundation
import SwiftUI


public class Actions: ObservableObject {
    @Published var isWorking: Bool
    @Published var log: String
    @Published var status: String
    @Published var verbose: Bool

    init() {
        isWorking = false
        log = ""
        status = "\n"
        verbose = false
    }
    
    func Install() {
        guard !isWorking else {
            addToLog(msg: "weedInstaller is busy")
            return
        }
        isWorking = true
        
        guard let bootstrapHelper = Bundle.main.path(forAuxiliaryExecutable: "bootstrapHelper") else {
            addToLog(msg: "Could not find bootstrapHelper")
            return
        }
        
        let tar = "/var/mobile/Documents/weedra1n/bootstrap.tar"
        guard FileManager().fileExists(atPath: tar) else {
            NSLog("[weedra1n] Could notfind Bootstrap")
            addToLog(msg: "Could not find bootstrap\nDownloading bootstrap")
            DispatchQueue.global(qos: .utility).async {
                let url = "https://github.com/Uckermark/weedra1n/raw/main/weedra1n/Required/bootstrap.tar"
                let ret = spawn(command: bootstrapHelper, args: ["-l", "-url", url], root: true)
                DispatchQueue.main.async {
                    self.addToLog(msg: "Finished downloading bootstrap. Tap Jailbreak again")
                    self.vLog(msg: ret.1)
                }
            }
            isWorking = false
            return
        }
         
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            addToLog(msg: "Could not find helper")
            isWorking = false
            return
        }
         
        guard let deb = Bundle.main.path(forResource: "org.coolstar.sileo_2.4_iphoneos-arm64", ofType: ".deb") else {
            NSLog("[weedra1n] Could not find deb")
            addToLog(msg: "Could not find Sileo deb")
            isWorking = false
            return
        }
        
        addToLog(msg: "Installing Bootstrap")
        DispatchQueue.global(qos: .utility).async { [self] in
            let ret1 = spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true).1
            let ret = spawn(command: helper, args: ["-i", tar], root: true)
            DispatchQueue.main.async {
                self.vLog(msg: ret1)
                if ret.0 != 0 {
                    self.addToLog(msg: "Error Installing Bootstrap")
                    self.isWorking = false
                    return
                }
                self.addToLog(msg: "Preparing Bootstrap")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: "/var/jb/usr/bin/sh", args: ["/var/jb/prep_bootstrap.sh"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        if ret.0 != 0 {
                            self.isWorking = false
                            return
                        }
                        self.addToLog(msg: "Installing Sileo")
                        DispatchQueue.global(qos: .utility).async {
                            let ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", deb], root: true)
                            DispatchQueue.main.async {
                                self.vLog(msg: ret.1)
                                if ret.0 != 0 {
                                    self.addToLog(msg: "Failed to install Sileo")
                                    self.isWorking = false
                                    return
                                }
                                self.addToLog(msg: "UICache Sileo")
                                DispatchQueue.global(qos: .utility).async {
                                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/Sileo.app"], root: true)
                                    DispatchQueue.main.async {
                                        self.vLog(msg: ret.1)
                                        if ret.0 != 0 {
                                            self.addToLog(msg: "Failed to run uicache")
                                            self.isWorking = false
                                            return
                                        }
                                        DispatchQueue.global(qos: .utility).async {
                                            self.runPatch()
                                            self.hideSystemApps()
                                            DispatchQueue.main.async {
                                                self.addToLog(msg: "Successfully installed Procursus and Sileo")
                                                self.isWorking = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func Remove() {
        guard !isWorking else {
            self.addToLog(msg: "weedInstaller is busy")
            return
        }
        isWorking = true
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            self.addToLog(msg: "Could not find helper")
            self.isWorking = false
            return
        }
        self.addToLog(msg: "Unregistering apps")
        DispatchQueue.global(qos: .utility).async { [self] in
            // for every .app file in /var/jb/Applications, run uicache -u
            let fm = FileManager.default
            let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        if ret.0 != 0 {
                            self.addToLog(msg: "Failed to unregister \(ret)")
                            self.isWorking = false
                            return
                        }
                    }
                }
            }
            self.addToLog(msg: "Removing Strap")
            let ret = spawn(command: helper, args: ["-r"], root: true)
            DispatchQueue.main.async { [self] in
                self.vLog(msg: ret.1)
                if ret.0 != 0 {
                    self.addToLog(msg: "Failed to remove Strap (\(ret))")
                    self.isWorking = false
                    return
                }
                self.addToLog(msg: "Strap removed!")
                self.isWorking = false
            }
        }
    }
    
    func runUiCache() {
        guard isJailbroken() else{
            addToLog(msg: "Could not find Bootstrap. Are you jailbroken?")
            return
        }
        // for every .app file in /var/jb/Applications, run uicache -p
        let fm = FileManager.default
        let apps = try? fm.contentsOfDirectory(atPath: "/var/jb/Applications")
        if apps == nil {
            self.addToLog(msg: "Could not access Applications")
            return
        }
        for app in apps ?? [] {
            if app.hasSuffix(".app") {
                let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-p", "/var/jb/Applications/\(app)"], root: true)
                self.vLog(msg: ret.1)
                self.addToLog(msg: "App \(app) refreshed")
                if ret.0 != 0 {
                    self.addToLog(msg: "Failed to rebuild IconCache (\(ret))")
                    return
                }
            }
        }
        self.addToLog(msg: "Rebuilt Icon Cache")
    }

    func remountPreboot() {
        let ret = spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        vLog(msg: ret.1)
        if ret.0 == 0 {
            addToLog(msg: "Remounted Preboot R/W")
        } else {
            addToLog(msg: "Failed to remount Preboot R/W")
        }
    }
    
    func launchDaemons() {
        guard isJailbroken() else{
            addToLog(msg: "Could not find Bootstrap. Are you jailbroken?")
            return
        }
        let ret = spawn(command: "/var/jb/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        vLog(msg: ret.1)
        if ret.0 != 0 && ret.0 != 34048 {
            addToLog(msg: "Failed to launch Daemons")
        } else {
            addToLog(msg: "Launched Daemons")
        }
    }
    
    func respringJB() {
        guard isJailbroken() else{
            addToLog(msg: "Could not find Bootstrap. Are you jailbroken?")
            return
        }
        let ret = spawn(command: "/var/jb/usr/bin/sbreload", args: [], root: true)
        vLog(msg: ret.1)
        if ret.0 != 0 {
            addToLog(msg: "Respring failed")
        }
    }
    
    func runTools() {
        guard isJailbroken() else {
            addToLog(msg: "Could not find Bootstrap. Are you jailbroken?")
            return
        }
        runUiCache()
        remountPreboot()
        launchDaemons()
        respringJB()
    }
    
    func addToLog(msg: String) {
        log = log + "\n" + "[*] " + msg
        status = msg
    }
    
    func vLog(msg: String) {
        if verbose {
            log = log + "\n" + msg
        }
    }
    
    func runPatch() {
        guard let url = Bundle.main.url(forResource: "patch", withExtension: ".sh")?.absoluteString else {
            addToLog(msg: "Could not find update script")
            return
        }
        let path = url.replacingOccurrences(of: "file://", with: "")
        DispatchQueue.main.async { [self] in
            addToLog(msg: "Upgrading packages")
        }
        let ret = spawn(command: "/var/jb/usr/bin/sh", args: [path], root: true)
        DispatchQueue.main.async { [self] in
            if ret.0 != 0 {
                addToLog(msg: "Failed to upgrade packages")
                vLog(msg: ret.1)
                vLog(msg: "script path: " + path)
                return
            }
        }
    }
    
    func isJailbroken() -> Bool {
        return FileManager().fileExists(atPath: "/var/jb/.procursus_strapped")
    }
    
    func downloadUpdate(UseDev: Bool) {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            addToLog(msg: "Could not find helper")
            return
        }
        addToLog(msg: "Downloading update")
        DispatchQueue.global(qos: .utility).async {
            let dArgs: [String]
            if UseDev { dArgs = ["-u", "--dev"] } else { dArgs = ["-u"] }
            let ret = spawn(command: helper, args: dArgs, root: true)
            DispatchQueue.main.async {
                self.vLog(msg: ret.1)
                self.addToLog(msg: "Extracting archive")
                DispatchQueue.global(qos: .utility).async {
                    let ret = spawn(command: helper, args: ["-e"], root: true)
                    DispatchQueue.main.async {
                        self.vLog(msg: ret.1)
                        self.addToLog(msg: "Finished Downloading. You can now install in the Settings tab")
                    }
                }
            }
        }
    }
    
    func removeDocDirectory() {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "weedra1nHelper") else {
            NSLog("[weedra1n] Could not find helper?")
            addToLog(msg: "Could not find helper")
            isWorking = false
            return
        }
        DispatchQueue.global(qos: .utility).async {
            spawn(command: helper, args: ["-c"], root: true)
        }
    }
    
    func hideSystemApps() {
        DispatchQueue.global(qos: .utility).async {
            let ret0 = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/Applications/Xcode Previews.app"], root: true)
            let ret1 = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/Applications/Sidecar.app"], root: true)
            DispatchQueue.main.async {
                self.vLog(msg: ret0.1 + ret1.1)
                self.addToLog(msg: "Removed Sidecar & Xcode Previews from springboard")
            }
        }
    }
}
