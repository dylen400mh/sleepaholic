//
//  ProfileView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-25.
//

//
//  ProfileView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileViewModel: UserProfileViewModel
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: String = ""
    
    private var email: String {
        AuthService.shared.currentUser?.email ?? ""
    }
    
    @State private var showGenderPicker = false
    private let genderOptions = ["Male", "Female", "Other"]
    
    var body: some View {
        VStack(spacing: 48) {
            // MARK: - Header
            HStack {
                BackButtonView(previous: { dismiss() })
                Spacer()
                Text("Profile")
                    .font(.h2Semi)
                    .foregroundColor(.white100)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            
            // MARK: - Form
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Email (non-editable)
                    ProfileRow(label: "Email", text: .constant(email))
                    SettingsSeparator()
                    
                    // Name
                    ProfileRow(label: "Name", editable: true, text: $name)
                    SettingsSeparator()
                    
                    // Age
                    ProfileRow(label: "Age", editable: true, keyboard: .numberPad, text: $age)
                    SettingsSeparator()
                    
                    // Gender
                    Button {
                        showGenderPicker = true
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.body1)
                                    .foregroundColor(.white70)
                                
                                Text(gender)
                                    .font(.body1Semi)
                                    .foregroundColor(.white100)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Image("down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white100)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .confirmationDialog("Select Gender", isPresented: $showGenderPicker) {
                        ForEach(genderOptions, id: \.self) { option in
                            Button(option) {
                                gender = option
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                    SettingsSeparator()
                    
                    // Delete Account
                    HStack {
                        Text("Delete Account")
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                        Spacer()
                        Button("Delete") {
                            // TODO: Add delete logic later
                        }
                        .font(.body1Semi)
                        .foregroundColor(.appRed)
                    }
                    SettingsSeparator()
                    
                    // Log Out
                    HStack {
                        Text("Log Out")
                            .font(.body1Semi)
                            .foregroundColor(.white100)
                        Spacer()
                        Button("Log Out") {
                            AuthService.shared.signOut()
                        }
                        .font(.body1Semi)
                        .foregroundStyle(Gradients.main)
                    }
                }
            }
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .appBackground()
        .task {
            await userProfileViewModel.loadProfile()
            if let profile = userProfileViewModel.profile {
                name = profile.name
                age = "\(profile.age)"
                gender = profile.gender
            }
        }
        .gesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
        .onChange(of: name) { _, _ in saveProfileIfValid() }
        .onChange(of: age) { _, _ in saveProfileIfValid() }
        .onChange(of: gender) { _, _ in saveProfileIfValid() }
    }
    
    // MARK: - Save Logic
    private func saveProfileIfValid() {
        guard isFormValid else { return }
        Task { await saveProfile() }
    }
    
    // MARK: - Validation
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(age) != nil &&
        !gender.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Save Logic
    private func saveProfile() async {
        guard var profile = userProfileViewModel.profile else { return }
        profile.name = name
        profile.age = Int(age) ?? 0
        profile.gender = gender
        await userProfileViewModel.saveProfile(profile)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(UserProfileViewModel())
    }
}

