//
//  SettingsView.swift
//  weedra1n
//
//  Created by Uckermark on 17.10.22.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var action: Actions
    @State var rootless: Bool = true
    @State var dev: Bool = false
    private let gitCommit = Bundle.main.infoDictionary?["REVISION"] as? String ?? "unknown"
    private let gitBranch = Bundle.main.infoDictionary?["BRANCH"] as? String ?? "unknown"
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    private var latestVersion: String?
    init(act: Actions) {
        latestVersion = try? String(contentsOf: URL(string: "https://raw.githubusercontent.com/Uckermark/uckermark.github.io/master/weedra1n")!).replacingOccurrences(of: "\n", with: "")
        if latestVersion == nil { latestVersion = version }
        action = act
    }
    var body: some View {
        VStack {
            List {
                Section(header: Text("UPDATE")) {
                    if latestVersion! != version && !FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/weedra1n.ipa") {
                        Button("Download Update to \(latestVersion!)", action: {action.downloadUpdate(UseDev: dev)})
                    }
                    else if FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/weedra1n.ipa") {
                        Button("Install") {
                            openURL(URL(string: "apple-magnifier://install?url=file:///var/mobile/Documents/weedra1n/weedra1n.ipa")!)
                        }
                    }
                    else {
                        Button("No update available", action: respring)
                            .disabled(true)
                    }
                }
                Section(header: Text("SETTINGS")) {
                    Toggle("Enable Verbose", isOn: $action.verbose)
                    Toggle("Use rootless", isOn: $rootless)
                        .disabled(true)
                    Toggle("Allow untested updates", isOn: $dev)
                }
                Section(header: Text("TOOLS")) {
                    Button("Rebuild Icon Cache") {
                        DispatchQueue.global(qos: .utility).async {
                            action.runUiCache()
                        }
                    }
                    Button("Remount Preboot", action: action.remountPreboot)
                    Button("Launch Daemons", action: action.launchDaemons)
                    Button("Respring", action: respring)
                    Button("Remove Sidecar & Xcode Previews", action: action.hideSystemApps)
                }
                Section {
                    Button("Restore RootFS", action: action.Remove)
                        .foregroundColor(.red)
                }
            }
            Spacer()
            HStack {
                Text("v\(version) (\(gitBranch), \(gitCommit))")
                Spacer()
            }
            Divider()
        }
        .background(Color(.systemGroupedBackground))
    }
}
