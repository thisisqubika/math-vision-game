import SwiftUI

@MainActor
struct GamePlayView: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            let awaiting = gameModel.countDown > 0
            playView
                .hidden(awaiting)
            countdownGauge
                .hidden(!awaiting)
        }
        .onReceive(timer) { _ in
            gameModel.updateCountdown(onCountdownIsZero: {
                Task {
                    await openImmersiveSpace(id: "mathVision")
                    gameModel.generateRounds()
                }
            })
            gameModel.syncTimeLeft()
        }
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
                timeLeftProgressView
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
            switch gameModel.state {
            case .result:
                VStack {
                    Text(verbatim: "\(String(format: "%02d", gameModel.score))")
                        .font(.system(size: 120))
                        .bold()
                    Text("score")
                        .font(.system(size: 60))
                        .bold()
                        .offset(y: -5)
                }
            case .playing:
                Text(verbatim: gameModel.currentRound?.question ?? "")
                    .font(.system(size: 60))
                    .bold()
            default:
                EmptyView()
            }
            Spacer()
        }
    }
    
    private var timeLeftProgressView: some View {
        let progress = Float(gameModel.timeLeft) / Float(GameModel.gameTime)
        return ProgressView(value: (progress > 1.0 || progress < 0.0) ? 1.0 : progress)
            .contentShape(.accessibility, Capsule().offset(y: -3))
            .tint(Color(uiColor: UIColor(red: 242 / 255, green: 68 / 255, blue: 206 / 255, alpha: 1.0)))
            .padding(.vertical, 30)
    }
}

#Preview {
    VStack {
        Spacer()
        GamePlayView()
            .environment(GameModel())
            .glassBackgroundEffect(
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
            .frame(width: 550, height: 550)
    }
}
