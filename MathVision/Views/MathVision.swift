/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view.
*/

import Combine
import SwiftUI
import RealityKit

struct MathVision: View {
    @Environment(GameModel.self) var gameModel
    
    @State private var subscriptions = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                switch gameModel.state {
                case .start:
                    Start()
                case .playing:
                    GamePlayView()
                case .result:
                    ResultView()
                }
            }
            .frame(width: 550, height: 550)
            .glassBackgroundEffect(
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
        }
    }
}

#Preview {
    MathVision()
        .environment(GameModel())
}

enum GameState {
    case start
    case playing
    case result
    
    var isPlaying: Bool {
        switch self {
        case .start, .result:
            false
        case .playing:
            true
        }
    }
}

