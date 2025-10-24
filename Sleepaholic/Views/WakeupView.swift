//
//  WakeupView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-09-13.
//

import SwiftUI

struct WakeupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var sleepLogViewModel: SleepLogViewModel
    @EnvironmentObject var windDown: WindDownManager
    
    @State private var manualWakeTime = Date()
    @State private var goHome = false
    @State private var showAlert = false
    @State private var alertType: AlertType? = nil
    @State private var showTimePicker = false
    
    enum AlertType {
        case currentTime
        case manualTime
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Image("SleepaholicLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 157, height: 28)
                Spacer()
                // preserve layout balance
                Color.clear.frame(width: 40, height: 40)
            }
            
            Spacer()
            
            // MARK: - Content
            VStack(spacing: 48) {
                // Top section
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Log Wake-Up")
                            .font(.h1Semi)
                            .foregroundColor(.white100)
                        Text("Confirm your wake-up time.")
                            .font(.body3)
                            .foregroundColor(.white80)
                    }
                    
                    Button {
                        alertType = .currentTime
                        showAlert = true
                    } label: {
                        PrimaryButton(
                            title: "Log Current Time",
                            icon: nil,
                            size: .regular,
                            isDisabled: false
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Separator
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color.white20)
                        .frame(height: 1)
                    Text("Or")
                        .font(.body3)
                        .foregroundColor(.white80)
                    Rectangle()
                        .fill(Color.white20)
                        .frame(height: 1)
                }
                
                // Manual section
                VStack(spacing: 24) {
                    TimeInputField(
                        label: "Log Time Manually",
                        date: $manualWakeTime,
                        onTap: { showTimePicker = true }
                    )
                    .frame(height: 56)
                    
                    Button {
                        alertType = .manualTime
                        showAlert = true
                    } label: {
                        SecondaryButton(
                            title: "Log Manual Time",
                            icon: nil,
                            size: .regular,
                            isDisabled: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goHome) {
            ContentView()
                .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                title: "Select Wake-Up Time",
                date: $manualWakeTime
            )
            .presentationDetents([.height(300), .medium])
            .presentationCornerRadius(24)
        }
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .currentTime:
                return Alert(
                    title: Text("Log Current Time?"),
                    message: Text("Are you sure you want to log your wake-up time as the current time?"),
                    primaryButton: .default(Text("Confirm")) {
                        Task {
                            await sleepLogViewModel.logWakeup(at: Date())
                            windDown.reset()
                            goHome = true
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .manualTime:
                return Alert(
                    title: Text("Log Manual Time?"),
                    message: Text("Are you sure you want to log your wake-up time as \(manualWakeTime.formatted(date: .omitted, time: .shortened))?"),
                    primaryButton: .default(Text("Confirm")) {
                        Task {
                            await sleepLogViewModel.logWakeup(at: manualWakeTime)
                            windDown.reset()
                            goHome = true
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .none:
                return Alert(title: Text(""))
            }
        }
        .appBackground()
    }
}

#Preview {
    WakeupView()
        .environmentObject(SleepLogViewModel())
        .environmentObject(WindDownManager())
}


