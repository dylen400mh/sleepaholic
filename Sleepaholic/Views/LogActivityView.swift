//
//  LogActivityView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-19.
//

import SwiftUI

struct LogActivityView: View {
    @Environment(\.adaptiveVerticalPadding) var adaptivePadding

    @Environment(\.dismiss) private var dismiss
    
    struct ActivityOption: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let destination: AnyView
    }
    
    private let options: [ActivityOption] = [
        .init(icon: "coffee", title: "Caffeine", destination: AnyView(LogCaffeineView())),
        .init(icon: "workout", title: "Workout", destination: AnyView(LogWorkoutView())),
        .init(icon: "alcohol", title: "Alcohol", destination: AnyView(LogAlcoholView())),
        .init(icon: "medication", title: "Medication", destination: AnyView(LogMedicationView())),
        .init(icon: "bed", title: "Nap", destination: AnyView(LogNapView()))
    ]
    
    var body: some View {
        VStack(spacing: 48) {
            HStack {
                // MARK: - Header
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Log Activity")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Content
            VStack(alignment: .leading, spacing: 32) {
                Text("Select the activity you wish to log.")
                    .font(.h2Semi)
                    .foregroundColor(.white100)

                VStack(spacing: 16) {
                    ForEach(options) { option in
                        NavigationLink(destination: option.destination) {
                            HStack(spacing: 12) {
                                Image(option.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white100)
                                Text(option.title)
                                    .font(.body1)
                                    .foregroundColor(.white100)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(Color.main)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, adaptivePadding)
        .padding(.horizontal, 24)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationBarBackButtonHidden(true)
        .appBackground()
    }
}

#Preview {
    NavigationStack {
        LogActivityView()
    }
}
