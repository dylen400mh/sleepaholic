//
//  ActivityRowView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-20.
//

import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            
            Image(iconName(for: activity.type))
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white100)
            
            VStack(alignment: .leading, spacing: 2) {
                switch activity.type {
                case "caffeine":
                    Text("Caffeine - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                    Text("\(activity.kind ?? "")\(activity.otherDescription != nil ? " (\(activity.otherDescription!))" : ""), \(activity.amountMg ?? 0)mg")
                        .font(.body3)
                        .foregroundColor(.white80)
                    
                case "workout":
                    Text("Workout - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                    Text("\(activity.kind ?? "")\(activity.otherDescription != nil ? " (\(activity.otherDescription!))" : ""), \(activity.durationMin ?? 0) min")
                        .font(.body3)
                        .foregroundColor(.white80)
                    
                case "alcohol":
                    Text("Alcohol - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                    Text("\(activity.drinks ?? 0) drink\( (activity.drinks ?? 0) == 1 ? "" : "s")")
                        .font(.body3)
                        .foregroundColor(.white80)
                    
                case "medication":
                    Text("Medication - \(activity.loggedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                    Text("\(activity.medication ?? ""), \(activity.amountMg ?? 0)mg")
                        .font(.body3)
                        .foregroundColor(.white80)
                    
                case "nap":
                    Text("Nap")
                        .font(.body1Semi)
                        .foregroundColor(.white100)
                    Text("\(activity.start?.formatted(date: .omitted, time: .shortened) ?? "") → \(activity.end?.formatted(date: .omitted, time: .shortened) ?? "")")
                        .font(.body3)
                        .foregroundColor(.white80)
                    
                default:
                    EmptyView()
                }
            }
            
            Spacer()
            
            Button(action: { showDeleteAlert = true }) {
                Image("x")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white100)
            }
            .buttonStyle(.plain)
            .alert("Delete Activity?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this activity? This action cannot be undone.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white5)
        .cornerRadius(12)
    }
    
    private func iconName(for type: String) -> String {
        switch type {
        case "caffeine": return "coffee"
        case "workout": return "workout"
        case "alcohol": return "alcohol"
        case "medication": return "medication"
        case "nap": return "bed"
        default: return "circle.fill"
        }
    }
}

