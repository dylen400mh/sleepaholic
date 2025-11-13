//
//  HeaderView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct HeaderView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding
    
    var body: some View {
        HStack {
            Image("SleepaholicLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 28)

            Spacer()
        }
        .padding(.top, adaptivePadding)
    }
}
