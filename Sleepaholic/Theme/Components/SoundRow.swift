//
//  SoundRow.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-21.
//

import SwiftUI

struct SoundRow: View {
    @EnvironmentObject var windDown: WindDownManager
    let items: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(items, id: \.self) { sound in
                SoundItem(sound: sound)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
