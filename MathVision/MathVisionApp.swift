import SwiftUI
import RealityKit

@MainActor @main
struct MathVisionApp: App {
    @State private var gameModel = GameModel()
    @State private var immersionState: ImmersionStyle = .mixed
    
    var body: some SwiftUI.Scene {
        WindowGroup("MathVision", id: "mathVisionApp") {
            MathVision()
                .environment(gameModel)
                .onAppear {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                        return
                    }
                        
                    windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: UIWindowScene.ResizingRestrictions.none))
                }
        }
        .windowStyle(.plain)
        
        ImmersiveSpace(id: "mathVision") {
            MathVisionSpace()
                .environment(gameModel)
        }
        .immersionStyle(selection: $immersionState, in: .mixed)
    }
}
