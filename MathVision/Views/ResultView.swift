import SwiftUI

@MainActor
struct ResultView: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack(spacing: 16) {
            hiFiveTitle
            greatJobSubtitle
            scoreMessage
            Group {
                playAgainButton
                backButton
            }
            .frame(width: 220)
        }
        .padding()
    }
    
    private var hiFiveTitle: some View {
        Image("hiFive")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 497, height: 200, alignment: .center)
            .accessibilityHidden(true)
    }
    
    private var greatJobSubtitle: some View {
        Text("Great job!")
            .font(.system(size: 36, weight: .bold))
    }
    
    private var scoreMessage: some View {
        Text(gameModel.scoreMessage)
            .multilineTextAlignment(.center)
            .font(.headline)
            .frame(width: 340)
            .padding(.bottom, 10)
    }
    
    private var playAgainButton: some View {
        Button(action: gameModel.playAgain) {
            Text("Play Again")
                .frame(maxWidth: .infinity)
        }
    }
    
    private var backButton: some View {
        Button {
            Task {
                await goBackToStart()
            }
        } label: {
            Text("Back to Main Menu")
                .frame(maxWidth: .infinity)
        }
    }
    
    private func goBackToStart() async {
        await dismissImmersiveSpace()
        gameModel.reset()
    }
}

#Preview {
    ResultView()
        .environment(GameModel())
        .glassBackgroundEffect(
            in: RoundedRectangle(
                cornerRadius: 32,
                style: .continuous
            )
        )
}
