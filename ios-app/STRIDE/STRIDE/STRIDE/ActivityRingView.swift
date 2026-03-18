import SwiftUI

struct ActivityRingView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let stepsProgress: Double
    var size: CGFloat = 200
    var lineWidth: CGFloat = 10

    @State private var animatedMove: Double = 0
    @State private var animatedExercise: Double = 0
    @State private var animatedSteps: Double = 0

    var body: some View {
        ZStack {
            // Steps ring (innermost)
            RingShape(progress: 1, lineWidth: lineWidth)
                .stroke(Color(hex: "007AFF").opacity(0.15), lineWidth: lineWidth)
                .frame(width: size - lineWidth * 4 * 2, height: size - lineWidth * 4 * 2)
            RingShape(progress: animatedSteps, lineWidth: lineWidth)
                .stroke(Color(hex: "007AFF"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size - lineWidth * 4 * 2, height: size - lineWidth * 4 * 2)
                .shadow(color: Color(hex: "007AFF").opacity(0.4), radius: 4)

            // Exercise ring (middle)
            RingShape(progress: 1, lineWidth: lineWidth)
                .stroke(Color(hex: "2DD4BF").opacity(0.15), lineWidth: lineWidth)
                .frame(width: size - lineWidth * 4, height: size - lineWidth * 4)
            RingShape(progress: animatedExercise, lineWidth: lineWidth)
                .stroke(Color(hex: "2DD4BF"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size - lineWidth * 4, height: size - lineWidth * 4)
                .shadow(color: Color(hex: "2DD4BF").opacity(0.4), radius: 4)

            // Move ring (outermost)
            RingShape(progress: 1, lineWidth: lineWidth)
                .stroke(Color(hex: "FC4C02").opacity(0.15), lineWidth: lineWidth)
                .frame(width: size, height: size)
            RingShape(progress: animatedMove, lineWidth: lineWidth)
                .stroke(Color(hex: "FC4C02"), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .shadow(color: Color(hex: "FC4C02").opacity(0.4), radius: 4)
        }
        .frame(width: size + lineWidth, height: size + lineWidth)
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
}

struct RingShape: Shape {
    var progress: Double
    var lineWidth: CGFloat = 10

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
            endAngle: .degrees(-90 + 360 * progress),
            clockwise: false
        )
        return path
    }
}

#Preview {
    ActivityRingView(
        moveProgress: 0.75,
        exerciseProgress: 0.6,
        stepsProgress: 0.85,
        size: 200
    )
    .padding()
    .background(Color.black)
}
