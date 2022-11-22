//
//  JailbreakView.swift
//  weedra1n
//
//  Created by Uckermark on 11.11.22.
//

import SwiftUI

struct JailbreakView: View {
    @ObservedObject var action: Actions
    
    var body: some View {
        VStack {
            Spacer()
            if !FileManager().fileExists(atPath: "/var/jb/.procursus_strapped") {
                Button("Jailbreak", action: action.Install)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            } else {
                Button("Re-jailbreak", action: action.runTools)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            Text(action.status)
                .padding()
                .foregroundColor(Color(.systemGroupedBackground))
                .colorInvert()
            Spacer()
            Divider()
        }
        .background(Color(.systemGroupedBackground))
    }
}
