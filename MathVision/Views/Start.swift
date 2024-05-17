import SwiftUI
import GroupActivities
@MainActor

struct Start: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            logo
            mathVisionTitle
            mathVisionDescription
            Spacer()
            startPlayingButton
            Spacer()
        }
    }
    
    private var logo: some View {
        Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 337, height: 211)
            .padding(.bottom)
    }
    
    private var mathVisionTitle: some View {
        Text("Math Vision")
            .font(.system(size: 30, weight: .bold))
    }
    
    private var mathVisionDescription: some View {
        Text("Unlock the magic of math with fun and interactive learning!")
            .multilineTextAlignment(.center)
            .font(.headline)
            .frame(width: 340)
            .padding(.bottom, 10)
    }
    
    private var startPlayingButton: some View {
        Button(action: gameModel.startPlaying) {
            Text("Play")
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 16, weight: .bold))
        .frame(width: 180)
    }
}

#Preview {
    Start()
        .environment(GameModel())
        .glassBackgroundEffect(
            in: RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
}
