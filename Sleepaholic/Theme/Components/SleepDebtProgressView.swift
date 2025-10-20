//
//  SleepDebtProgressView.swift
//  Sleepaholic
//
//  Created by Dylen Belanger on 2025-10-19.
//

import SwiftUI

struct SleepDebtProgressView: View {
    let progress: CGFloat
    let sleepDebt: String
    
    private let outerSize: CGFloat = 324
    private let ringSize: CGFloat  = 312        // where the arc lives
    private let ringWidth: CGFloat = 36         // track thickness (drawn INSIDE the 312 frame)
    private let ticksSize: CGFloat = 241.55     // inner tick circle
    private let ticksLine: CGFloat = 3.79
    
    private let startAngle = Angle(degrees: -90)

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.dark)
                .frame(width: outerSize, height: outerSize)
            
            // Unfilled track (full 360 arc)
            Arc(start: startAngle, end: startAngle + .degrees(360))
                .stroke(Color.main, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .frame(width: ringSize - ringWidth, height: ringSize - ringWidth)

            // Filled progress arc
            Arc(start: startAngle, end: startAngle + .degrees(360.0 * Double(progress)))
                .stroke(Gradients.main, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .frame(width: ringSize - ringWidth, height: ringSize - ringWidth)
            
            Circle()
                .stroke(
                    Color.white50,
                    style: StrokeStyle(
                        lineWidth: ticksLine,
                        lineCap: .butt,
                        dash: [1, 5]
                    )
                )
                .frame(width: ticksSize - 16, height: ticksSize - 16)
            
            iconAt(angle: startAngle, iconName: "moon")
            iconAt(angle: startAngle + .degrees(360.0 * Double(progress)), iconName: "stopwatch")

            VStack(spacing: 0) {
                Text("Sleep Debt")
                    .font(.body1)
                    .foregroundColor(.white80)
                Text(sleepDebt)
                    .font(.h1Semi)
                    .foregroundColor(.white100)
            }
        }
        .frame(width: outerSize, height: outerSize)
    }
    
    // MARK: - Helper to place icons at a given angle along the ring
    @ViewBuilder
    private func iconAt(angle: Angle, iconName: String) -> some View {
        let radius = (ringSize - ringWidth) / 2   // follow arc’s center line
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let x = center.x + radius * cos(CGFloat(angle.radians))
            let y = center.y + radius * sin(CGFloat(angle.radians))
            
            ZStack {
                Circle()
                    .fill(Color.main)
                    .frame(width: 27.87, height: 27.87)
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white100)
            }
            .position(x: x, y: y)
        }
        .frame(width: outerSize, height: outerSize)
    }
}

// Simple arc shape that draws INSIDE its frame (so we keep inner/outer dark margins)
private struct Arc: Shape {
    var start: Angle
    var end: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) / 2
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: r,
                 startAngle: start,
                 endAngle: end,
                 clockwise: false)
        return p
    }
}
