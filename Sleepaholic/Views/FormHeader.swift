//
//  FormHeader.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct FormHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .padding(8)
            }
            Spacer()
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            Spacer().frame(width: 32)
        }
        .padding()
    }
}


#Preview {
    FormHeader(title: "Caffeine")
}
