//
//  HeaderView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Image("SleepaholicLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)

            
            Spacer()
            
            NavigationLink(destination: SettingsView()) {
                Image("settings")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white40, lineWidth: 0.5)
                            .background(Color.clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
        }
        .padding(.top, 60)
    }
}
