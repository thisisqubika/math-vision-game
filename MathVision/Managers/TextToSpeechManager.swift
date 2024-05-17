// Created by Bruno Martinez on 17/5/24.

import AVKit

class TextToSpeechManager {
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechSynthesizer.speak(speechUtterance)
    }
}
