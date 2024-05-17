import SwiftUI

@MainActor
struct GamePlayView: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        ZStack {
            let awaiting = gameModel.countDown > 0
            playView
                .hidden(awaiting)
            countdownGauge
                .hidden(!awaiting)
        }
        .frame(width: 550, height: 550)
    }
    
    private var playView: some View {
        VStack(spacing: 0) {
            HStack {
                dismissImmersiveSpaceButton
                Spacer()
            }
            Spacer()
            scoreStack
            Spacer()
            HStack {
                muteButton
                timeLeftProgressView
                playPauseButton
            }
            .background(
                .regularMaterial,
                in: .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )
        }
    }
    
    private var countdownGauge: some View {
        Gauge(value: gameModel.countdownProgressValue) {
            EmptyView()
        }
        .labelsHidden()
        .animation(.default, value: gameModel.countdownProgressValue)
        .gaugeStyle(.accessoryCircularCapacity)
        .scaleEffect(x: 3, y: 3, z: 1)
        .padding(50)
        .overlay {
            Text(verbatim: "\(gameModel.countDown)")
                .animation(.none, value: gameModel.countdownProgressValue)
                .font(.system(size: 64))
                .bold()
        }
    }
    
    private var dismissImmersiveSpaceButton: some View {
        Button {
            Task {
                await dismissImmersiveSpace()
            }
            gameModel.reset()
        } label: {
            Label("Back", systemImage: "chevron.backward")
                .labelStyle(.iconOnly)
        }
        .padding([.leading, .top], 32)
    }
    
    private var scoreStack: some View {
        HStack {
            Spacer()
            VStack {
                Text(verbatim: "\(String(format: "%02d", gameModel.score))")
                    .font(.system(size: 120))
                    .bold()
                Text("score")
                    .font(.system(size: 60))
                    .bold()
                    .offset(y: -5)
            }
            Spacer()
        }
    }
    
    private var muteButton: some View {
        Button(action: gameModel.onToggleMuted) {
            Label(
                gameModel.isMuted ? "Play music" : "Stop music",
                systemImage: gameModel.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill"
            )
            .labelStyle(.iconOnly)
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
    }
    
    private var timeLeftProgressView: some View {
        let progress = Float(gameModel.timeLeft) / Float(GameModel.gameTime)
        return ProgressView(value: (progress > 1.0 || progress < 0.0) ? 1.0 : progress)
            .contentShape(.accessibility, Capsule().offset(y: -3))
            .tint(Color(uiColor: UIColor(red: 242 / 255, green: 68 / 255, blue: 206 / 255, alpha: 1.0)))
            .padding(.vertical, 30)
    }
    
    private var playPauseButton: some View {
        Button(action: gameModel.onPlayPause) {
            if gameModel.state.isPlaying {
                Label("Pause", systemImage: "pause.fill")
                    .labelStyle(.iconOnly)
            } else {
                Label("Play", systemImage: "play.fill")
                    .labelStyle(.iconOnly)
            }
        }
        .padding(.trailing, 12)
        .padding(.leading, 10)
    }
}

#Preview {
    VStack {
        Spacer()
        GameScoreView()
            .environment(GameModel())
            .glassBackgroundEffect(
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
    }
}
