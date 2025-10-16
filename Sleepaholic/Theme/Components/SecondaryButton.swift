//
//  SecondaryButton.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-15.
//

import SwiftUI

struct SecondaryButton: View {
    enum Size {
        case regular
        case small
    }

    let title: String
    let icon: Image?
    let size: Size
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(font)
                    .foregroundColor(.white100)

                if let icon = icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: width, height: height)
            .background(Color.main)
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .strokeBorder(Gradients.main, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Layout constants
    private var width: CGFloat {
        switch size {
        case .regular: return 342
        case .small: return 147
        }
    }

    private var height: CGFloat {
        switch size {
        case .regular: return 56
        case .small: return 48
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .regular: return 24
        case .small: return 16
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .regular: return 16
        case .small: return 12
        }
    }

    private var font: Font {
        switch size {
        case .regular: return .body1Semi
        case .small: return .body2Semi
        }
    }
}
