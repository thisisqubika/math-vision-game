/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's model type for game state and gameplay information.
*/

import AsyncQueue
import AVKit
import RealityKit
import SwiftUI

struct Round {
    let question: String
    let answers: [Int]
    let correctAnswer: Int
}

/// State that drives the different screens of the game and options that players select.
@MainActor @Observable
class GameModel {
    static let gameTime = 15
    let spaceOrigin = Entity()

    var rounds: [Round] = []
    var currentRound: Round? {
        rounds[safe: currentRoundIndex]
    }
    var currentRoundIndex: Int = 0
    var state: GameState = .start
    var ready = false
    var timeLeft = gameTime
    var balloons: [Entity] = []
    var countDown = 3
    var countdownProgressValue: Float {
        min(1, max(0, Float(countDown) / 3.0 + 0.01))
    }
    var score = 0
    let ttsManager = TextToSpeechManager()

    /// Removes 3D content when then game is over.
    func clear3Dcontent() {
        spaceOrigin.children.removeAll()
    }
    
    /// Resets game state information.
    func reset() {
        state = .start
        ready = false
        timeLeft = GameModel.gameTime
        countDown = 3
        score = 0
        clear3Dcontent()
        generateRounds()
    }
    
    func startPlaying() {
        state = .playing
        timeLeft = GameModel.gameTime
    }

    func playAgain() {
        reset()
        state = .playing
    }

    func updateCountdown(onCountdownIsZero: @escaping () -> Void) {
        if countDown > 0 {
            var attrStr = AttributedString("\(countDown)")
            attrStr.accessibilitySpeechAnnouncementPriority = .high
            AccessibilityNotification.Announcement("\(countDown)").post()
            countDown -= 1
            if countDown == 0 {
                ready = true
                onCountdownIsZero()
            }
        }
    }
    
    func syncTimeLeft() {
        guard ready && state.isPlaying else { return }
        if timeLeft > 0 {
            timeLeft -= 1
        } else {
            nextRound()
        }
    }
    
    func onAnswer(entity: Entity) {
        guard let currentRound, let balloonComponent = entity.components[Balloon.self] else { return }
        
        if balloonComponent.answer == currentRound.correctAnswer {
            ttsManager.speak(text: "Correct! Good Job!")
            explodeBalloon(entity, color: balloonComponent.color)
            MainActorQueue.shared.enqueue {
                try? await Task.sleep(for: .seconds(0.25))
                self.nextRound(exploteColor: .clear)
            }
        } else {
            ttsManager.speak(text: "Incorrect")
            explodeAllBalloons()
        }
    }
    
    func nextRound(exploteColor: UIColor = .white) {
        if currentRoundIndex == rounds.count - 1 {
            state = .result
            clear3Dcontent()
            timeLeft = -1
        } else {
            currentRoundIndex += 1
            timeLeft = GameModel.gameTime
            MainActorQueue.shared.enqueue {
                do {
                    self.balloons.forEach { self.explodeBalloon($0, color: exploteColor) }
                    self.balloons = try await self.spawnAndAnimateBalloons(options: self.currentRound?.answers ?? [])
                    self.explainRound()
                } catch {
                    print("Error", error.localizedDescription)
                }
            }
        }
    }
    
    func generateRounds() {
        rounds = [generateRound(), generateRound()]
        MainActorQueue.shared.enqueue {
            do {
                self.balloons = try await self.spawnAndAnimateBalloons(
                    options: self.currentRound?.answers ?? []
                )
                self.explainRound()
            } catch {
                print("Error" , error.localizedDescription)
            }
        }
    }

    private func generateRound() -> Round {
        // Generate two random numbers between 1 and 10
        let number1 = Int.random(in: 1...10)
        let number2 = Int.random(in: 1...10)
        
        // Calculate the correct answer
        let correctAnswer = number1 + number2
        
        // Create the question
        let question = "What is \(number1) plus \(number2)?"
        
        // Generate incorrect answers
        var answers = [Int]()
        answers.append(correctAnswer)
        
        while answers.count < 3 {
            // Generate a random number for the incorrect answer
            let range = max(1, correctAnswer - 3)...min(20, correctAnswer + 3)
            let incorrectAnswer = Int.random(in: range)
            // Ensure the incorrect answer is not the same as the correct one and not already included
            if incorrectAnswer != correctAnswer && !answers.contains(incorrectAnswer) {
                answers.append(incorrectAnswer)
            }
        }
        
        // Shuffle the answers so the correct one isn't always in the same position
        answers.shuffle()
        
        return .init(question: question, answers: answers, correctAnswer: correctAnswer)
    }

    
    public func explainRound() {
        guard let currentRound else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.ttsManager.speak(text: currentRound.question)
        }
    }
}

class TextToSpeechManager {
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(speechUtterance)
    }
}
