import SwiftUI

struct ActivityRingView: View {
    let moveProgress: Double
    let exerciseProgress: Double
    let stepsProgress: Double
    let size: CGFloat
    let strokeWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.strideBorder, lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: moveProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.stridePrimary, Color.stridePrimaryLight]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.stridePrimary.opacity(0.5), radius: 8)

            VStack(spacing: 4) {
                Text("\(Int(moveProgress * 100))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.strideText)

                Text("Move Goal")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.strideSecondary)
            }
        }
        .frame(width: size, height: size)
        .padding(20)
    }
}

#Preview {
    ZStack {
        Color.strideBackground
            .ignoresSafeArea()

        ActivityRingView(
            moveProgress: 0.75,
            exerciseProgress: 0.6,
            stepsProgress: 0.85,
            size: 200,
            strokeWidth: 12
        )
    }
}
