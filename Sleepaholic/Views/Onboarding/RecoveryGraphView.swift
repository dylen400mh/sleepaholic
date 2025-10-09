//
//  RecoveryGraphView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-08.
//

import SwiftUI

struct RecoveryGraphView: View {
    let next: () -> Void
    let previous: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Back Button
            BackButtonView(previous: previous)
                .padding(.top)

            Spacer(minLength: 20)

            // Title
            Text("Recovery Benefits")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)

            // Chart Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep Progress")
                    .font(.headline)
                    .padding(.horizontal)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)

                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height = geometry.size.height

                        ZStack {
                            // Background gridlines
                            VStack {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 1)
                                        .padding(.vertical, 12)
                                }
                            }

                            // Sleepaholic Line (smoothly climbing with natural wobble)
                            Path { path in
                                path.move(to: CGPoint(x: width * 0.05, y: height * 0.8))
                                path.addCurve(
                                    to: CGPoint(x: width * 0.25, y: height * 0.65),
                                    control1: CGPoint(x: width * 0.15, y: height * 0.75),
                                    control2: CGPoint(x: width * 0.20, y: height * 0.7)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.45, y: height * 0.5),
                                    control1: CGPoint(x: width * 0.3, y: height * 0.55),
                                    control2: CGPoint(x: width * 0.4, y: height * 0.45)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.65, y: height * 0.4),
                                    control1: CGPoint(x: width * 0.52, y: height * 0.55),
                                    control2: CGPoint(x: width * 0.6, y: height * 0.35)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.9, y: height * 0.25),
                                    control1: CGPoint(x: width * 0.7, y: height * 0.45),
                                    control2: CGPoint(x: width * 0.85, y: height * 0.3)
                                )
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 3, x: 0, y: 2)

                            // Conventional Line (flatter, less progress)
                            Path { path in
                                path.move(to: CGPoint(x: width * 0.05, y: height * 0.8))
                                path.addCurve(
                                    to: CGPoint(x: width * 0.25, y: height * 0.75),
                                    control1: CGPoint(x: width * 0.15, y: height * 0.78),
                                    control2: CGPoint(x: width * 0.22, y: height * 0.76)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.45, y: height * 0.7),
                                    control1: CGPoint(x: width * 0.3, y: height * 0.73),
                                    control2: CGPoint(x: width * 0.4, y: height * 0.68)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.65, y: height * 0.65),
                                    control1: CGPoint(x: width * 0.52, y: height * 0.7),
                                    control2: CGPoint(x: width * 0.58, y: height * 0.63)
                                )
                                path.addCurve(
                                    to: CGPoint(x: width * 0.9, y: height * 0.6),
                                    control1: CGPoint(x: width * 0.7, y: height * 0.67),
                                    control2: CGPoint(x: width * 0.85, y: height * 0.62)
                                )
                            }
                            .stroke(Color.red.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

                            // Floating labels beside line endpoints
                            Group {
                                Text("Sleepaholic")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.accentColor)
                                    .position(
                                        x: width * 0.93,
                                        y: height * 0.15
                                    )

                                Text("Conventional")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .position(
                                        x: width * 0.93,
                                        y: height * 0.5
                                    )
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
                .frame(height: 220)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            .padding(.horizontal)

            // Description
            Text("Sleepaholic helps improve your sleep 68% faster than trying on your own. 📈")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            // Continue Button
            Button {
                next()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    RecoveryGraphView(next: {}, previous: {})
}
