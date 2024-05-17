/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The space where the game takes place.
*/

import Accelerate
import AVKit
import Combine
import GameController
import RealityKit
import SwiftUI
import MathVisionAssets

/// The Full Space that displays when someone plays the game.
@MainActor
struct MathVisionSpace: View {
    @Environment(GameModel.self) var gameModel
    
    var tap: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { target in
                gameModel.onAnswer(entity: target.entity)
            }
    }
    
    var body: some View {
        RealityView { content in
            content.add(spaceOrigin)
        } update: { updateContent in
            
        }
        .gesture(tap.targetedToAnyEntity())
    }
}
