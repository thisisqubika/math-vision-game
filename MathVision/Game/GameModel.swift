import AsyncQueue
import RealityKit
import SwiftUI

@MainActor @Observable
class GameModel {
    
    // MARK: Public
    
    // Space
    let spaceOrigin = Entity()
    var rounds: [Round] = []
    var currentRoundIndex: Int = 0
    var currentRound: Round? {
        rounds[safe: currentRoundIndex]
    }
    var state: GameState = .start
    var timeLeft = gameTime
    var countDown = 3
    var countdownProgressValue: Float {
        min(1, max(0, Float(countDown) / 3.0 + 0.01))
    }
    var score = 0
    var scoreMessage: String {
        "You've completed \(score) rounds. Keep up the great learning!"
    }
    var balloons: [Entity] = []
    let ttsManager = TextToSpeechManager()
    
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
                onCountdownIsZero()
            }
        }
    }
    
    func syncTimeLeft() {
        guard countDown <= 0 && state.isPlaying else { return }
        if timeLeft > 0 {
            timeLeft -= 1
        } else {
            ttsManager.speak(text: "Timeout!")
            nextRound(didSucceedCurrentRound: false)
        }
    }
    
    func onAnswer(entity: Entity) {
        guard let currentRound, let balloon = entity.components[Balloon.self] else { return }
        
        if balloon.answer == currentRound.correctAnswer {
            score += 1
            ttsManager.speak(text: "Correct! Good Job!")
            explodeBalloon(entity, balloon: balloon)
            MainActorQueue.shared.enqueue {
                try? await Task.sleep(for: .seconds(0.25))
                self.nextRound(didSucceedCurrentRound: true)
            }
        } else {
            ttsManager.speak(text: "Incorrect")
            explodeAllBalloons()
        }
    }
    
    func nextRound(didSucceedCurrentRound: Bool) {
        if currentRoundIndex == rounds.count - 1 {
            state = .result
            ttsManager.speak(text: scoreMessage)
            clear3Dcontent()
            timeLeft = -1
        } else {
            currentRoundIndex += 1
            timeLeft = GameModel.gameTime
            MainActorQueue.shared.enqueue {
                do {
                    if didSucceedCurrentRound {
                        self.clear3Dcontent()
                    } else {
                        self.balloons.forEach {
                            guard let balloon = $0.components[Balloon.self] else { return }
                            self.explodeBalloon($0, balloon: balloon)
                        }
                    }
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
    
    public func explainRound() {
        guard let currentRound else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.ttsManager.speak(text: currentRound.question)
        }
    }
    
    func reset() {
        state = .start
        timeLeft = GameModel.gameTime
        currentRoundIndex = 0
        countDown = 3
        score = 0
        clear3Dcontent()
    }
    
    // MARK: Private

    private func clear3Dcontent() {
        spaceOrigin.children.removeAll()
    }

    private func generateRound() -> Round {
        let number1 = Int.random(in: 1...10)
        let number2 = Int.random(in: 1...10)
        let correctAnswer = number1 + number2
        let question = "What is \(number1) plus \(number2)?"
        var answers = [Int]()
        answers.append(correctAnswer)
        
        while answers.count < 3 {
            let range = max(1, correctAnswer - 3)...min(20, correctAnswer + 3)
            let incorrectAnswer = Int.random(in: range)
            if incorrectAnswer != correctAnswer && !answers.contains(incorrectAnswer) {
                answers.append(incorrectAnswer)
            }
        }
        
        answers.shuffle()
        
        return .init(question: question, answers: answers, correctAnswer: correctAnswer)
    }
    
    // MARK: Static

    static let gameTime = 15
}
