//
//  HeaderView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct HeaderView: View {
    var title: String = "Sleepaholic"
    var settingsAction: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: settingsAction) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
            }
        }
        .padding()
    }
}
