/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declarations and parameters for clouds and their movement.
*/

import UIKit
import Spatial
import RealityKit

extension GameModel {
    static let balloonColors: [UIColor] = [
        UIColor(red: 255/255, green: 99/255, blue: 71/255, alpha: 1),   // Tomato
        UIColor(red: 30/255, green: 144/255, blue: 255/255, alpha: 1),  // Dodger Blue
        UIColor(red: 255/255, green: 105/255, blue: 180/255, alpha: 1), // Hot Pink
        UIColor(red: 50/255, green: 205/255, blue: 50/255, alpha: 1),   // Lime Green
        UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1),   // Gold
        UIColor(red: 138/255, green: 43/255, blue: 226/255, alpha: 1),  // Blue Violet
        UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)    // Orange
    ]
    
    // MARK: Public
    
    func spawnAndAnimateBalloons(options: [Int]) async throws -> [Entity] {
        let horizontalStartPositions: [Float] = [-0.25, 0, 0.25]
        
        let startHeight: Float = 1
        let endHeight: Float = 4
        var colors = Self.balloonColors
        
        var balloons: [Entity] = []
        for (index, number) in options.enumerated() {
            let balloonColor = colors.randomElement() ?? .white
            colors.removeAll(where: { $0 == balloonColor })
            let balloonComponent = Balloon(
                id: UUID.init(),
                color: balloonColor,
                answer: number
            )
            let balloonEntity = createBalloon(withNumber: number, component: balloonComponent)
            let xPos = horizontalStartPositions[index]
            balloonEntity.position = SIMD3<Float>(xPos, startHeight, 0)
            balloonEntity.components.set(
                Balloon(
                    id: UUID.init(),
                    color: balloonColor,
                    answer: number
                )
            )
            balloonEntity.components[InputTargetComponent.self] = InputTargetComponent()
            balloonEntity.components[CollisionComponent.self] = CollisionComponent(
                shapes: [.generateSphere(radius: 0.1)],
                mode: .trigger,
                filter: .default
            )
            spaceOrigin.addChild(balloonEntity)
            
            let animation = generateBalloonMovementAnimation(from: xPos, startY: startHeight, to: endHeight)
            balloonEntity.playAnimation(animation, transitionDuration: 0.0, startsPaused: false)
            balloons.append(balloonEntity)
        }
        
        return balloons
    }

    @MainActor
    func explodeAllBalloons() {
        for entity in spaceOrigin.children where entity.components.has(Balloon.self) {
            guard let balloon = entity.components[Balloon.self] else { continue }
            explodeBalloon(entity, balloon: balloon)
        }
    }
    
    @MainActor
    func explodeBalloon(_ entity: Entity, balloon: Balloon) {
        createExplosionDebris(at: entity.position, spreadDuration: 1.0, balloon: balloon)
        entity.removeFromParent()
    }
    
    // MARK: Private

    private func createBalloon(withNumber number: Int, component: Balloon) -> Entity {
        let sphereMesh = MeshResource.generateSphere(radius: 0.1)
        let balloonMaterial = SimpleMaterial(color: component.color, isMetallic: false)
        let balloonEntity = ModelEntity(mesh: sphereMesh, materials: [balloonMaterial])
        addSimulatedCurvedStringToBalloon(balloonEntity, color: .white)
        addBowToBalloon(balloonEntity, balloon: component)
        addTextToBalloon(balloonEntity, number: number)
        return balloonEntity
    }
    
    private func addTextToBalloon(_ entity: Entity, number: Int) {
        let fontSize: CGFloat = 0.15
        let frameWidth: CGFloat = 0.4
        let frameHeight: CGFloat = 0.2
        
        let textMesh = MeshResource.generateText(
            "\(number)",
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: fontSize, weight: .bold),
            containerFrame: CGRect(x: -frameWidth / 2, y: -frameHeight / 2, width: frameWidth, height: frameHeight),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textEntity.position = [0, 0, 0.11]
        textEntity.scale = SIMD3<Float>(repeating: 0.5)
        entity.addChild(textEntity)
    }
    
    private func addSimulatedCurvedStringToBalloon(_ entity: Entity, color: UIColor) {
        let segmentCount = 10
        let segmentLength: Float = 0.04
        let curveAmount: Float = 0.002
        var previousSegment: Entity? = nil
        for i in 0..<segmentCount {
            let segment = MeshResource.generateCylinder(height: segmentLength, radius: 0.001)
            let material = SimpleMaterial(color: color, isMetallic: false)
            let segmentEntity = ModelEntity(mesh: segment, materials: [material])
            
            segmentEntity.position.y = -Float(i) * segmentLength
            if let prev = previousSegment {
                segmentEntity.position.x = prev.position.x + (i % 2 == 0 ? -curveAmount : curveAmount)
            }
            
            entity.addChild(segmentEntity)
            previousSegment = segmentEntity
        }
    }
    
    
    private func addBowToBalloon(_ entity: Entity, balloon: Balloon) {
        let bowWidth: Float = 0.03
        let bowHeight: Float = 0.02
        let bowDepth: Float = 0.01
        
        let knot = MeshResource.generateBox(width: bowDepth, height: bowDepth, depth: bowDepth)
        let knotMaterial = SimpleMaterial(color: balloon.color, isMetallic: false)
        let knotEntity = ModelEntity(mesh: knot, materials: [knotMaterial])
        knotEntity.position = [0, -0.1, 0]
        entity.addChild(knotEntity)
        
        let loopCount = 2
        for i in 0..<loopCount {
            let loop = MeshResource.generateCylinder(height: bowHeight, radius: bowDepth / 2)
            let loopMaterial = SimpleMaterial(color: balloon.color, isMetallic: false)
            let loopEntity = ModelEntity(mesh: loop, materials: [loopMaterial])
            
            let angle = Float.pi / 2 * Float(i)
            loopEntity.position = [bowWidth * (i % 2 == 0 ? 1 : -1) * 0.5, -0.1, 0]
            loopEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])
            entity.addChild(loopEntity)
        }
    }

    @MainActor
    private func createExplosionDebris(at position: SIMD3<Float>, spreadDuration: TimeInterval, balloon: Balloon) {
        for _ in 0..<10 {
            let fragment = MeshResource.generateSphere(radius: 0.02)
            let material = SimpleMaterial(color: balloon.color, isMetallic: false)
            let fragmentEntity = ModelEntity(mesh: fragment, materials: [material])
            fragmentEntity.position = position
            fragmentEntity.components.set(Explosion())
            
            spaceOrigin.addChild(fragmentEntity)
            
            let direction = SIMD3<Float>(Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5), Float.random(in: -0.5...0.5))
            let finalPosition = fragmentEntity.transform.translation + direction
            
            fragmentEntity.move(
                to: Transform(translation: finalPosition),
                relativeTo: nil,
                duration: spreadDuration,
                timingFunction: .easeOut
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + spreadDuration) {
                fragmentEntity.removeFromParent()
            }
        }
    }

    @MainActor
    private func generateBalloonMovementAnimation(from startX: Float, startY: Float, to endY: Float) -> AnimationResource {
        let start = SIMD3<Float>(startX, startY, -1)
        let end = SIMD3<Float>(startX, endY, -1)
        
        let line = FromToByAnimation<Transform>(
            name: "rise",
            from: .init(scale: .init(repeating: 1), translation: start),
            to: .init(scale: .init(repeating: 1), translation: end),
            duration: 30.0,
            bindTarget: .transform
        )
        
        do {
            let animation = try AnimationResource.generate(with: line)
            return animation
        } catch {
            fatalError("Failed to create balloon movement animation: \(error)")
        }
    }
}
