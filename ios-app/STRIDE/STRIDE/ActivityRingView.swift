//
//  ActivityRingView.swift
//  STRIDE
//
//  Created by Giritharan Chockalingam on 3/17/26.
//

import SwiftUI

struct ActivityRingView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let stepsProgress: Double
    var size: CGFloat = 200
    var lineWidth: CGFloat = 12

    @State private var animatedMove: Double = 0
    @State private var animatedExercise: Double = 0
    @State private var animatedSteps: Double = 0

    private var ringGap: CGFloat { lineWidth * 1.5 }

    var body: some View {
        ZStack {
            // Steps ring (innermost)
            ringPair(
                progress: animatedSteps,
                color: Config.Colors.stepsRing,
                diameter: size - ringGap * 4
            )

            // Exercise ring (middle)
            ringPair(
                progress: animatedExercise,
                color: Config.Colors.exerciseRing,
                diameter: size - ringGap * 2
            )

            // Move ring (outermost)
            ringPair(
                progress: animatedMove,
                color: Config.Colors.moveRing,
                diameter: size
            )
        }
        .frame(width: size + lineWidth * 2, height: size + lineWidth * 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedMove = min(moveProgress, 1.0)
                animatedExercise = min(exerciseProgress, 1.0)
                animatedSteps = min(stepsProgress, 1.0)
            }
        }
        .onChange(of: moveProgress) { _, new in
            withAnimation(.easeInOut(duration: 0.8)) { animatedMove = min(new, 1.0) }
        }
        .onChange(of: exerciseProgress) { _, new in
            withAnimation(.easeInOut(duration: 0.8)) { animatedExercise = min(new, 1.0) }
        }
        .onChange(of: stepsProgress) { _, new in
            withAnimation(.easeInOut(duration: 0.8)) { animatedSteps = min(new, 1.0) }
        }
    }

    private func ringPair(progress: Double, color: Color, diameter: CGFloat) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            // Progress arc
            RingShape(progress: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color, color.opacity(0.7), color]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)

            // End cap glow
            if progress > 0.02 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth * 0.6, height: lineWidth * 0.6)
                    .shadow(color: color, radius: 6)
                    .offset(y: -diameter / 2)
                    .rotationEffect(.degrees(360 * progress - 90))
            }
        }
    }
}

struct RingShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * min(progress, 1.0)),
            clockwise: false
        )
        return path
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            ActivityRingView(
                moveProgress: 0.75,
                exerciseProgress: 0.6,
                stepsProgress: 0.85,
                size: 200,
                lineWidth: 14
            )

            ActivityRingView(
                moveProgress: 0.45,
                exerciseProgress: 0.3,
                stepsProgress: 0.6,
                size: 120,
                lineWidth: 10
            )
        }
    }
}
