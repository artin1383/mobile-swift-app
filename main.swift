import Foundation

struct Game {
    var secretCode: [Int]
    
    init() {
        secretCode = (0..<4).map { _ in Int.random(in: 1...6) }
    }
    
    func checkGuess(guess: [Int]) -> String {
        var blackPins = 0
        var whitePins = 0
        var secretCodeCopy = secretCode
        var guessCopy = guess
        
        for i in 0..<4 {
            if guess[i] == secretCode[i] {
                blackPins += 1
                secretCodeCopy[i] = -1
                guessCopy[i] = -2
            }
        }
        
        for i in 0..<4 {
            if guessCopy[i] != -2, let index = secretCodeCopy.firstIndex(of: guessCopy[i]) {
                whitePins += 1
                secretCodeCopy[index] = -1
            }
        }
        
        return String(repeating: "B", count: blackPins) + String(repeating: "W", count: whitePins)
    }
}

let game = Game()
print("Welcome to Mastermind!")
print("Guess the 4-digit code. Each digit is between 1-6.")
print("Type 'exit' to quit.")

while true {
    print("\nEnter your guess: ", terminator: "")
    guard let input = readLine() else {
        print("Invalid input. Try again.")
        continue
    }
    
    if input.lowercased() == "exit" {
        print("Thanks for playing! The secret code was \(game.secretCode).")
        exit(0)
    }
    
    let guess = input.compactMap { Int(String($0)) }
    if guess.count != 4 || !guess.allSatisfy({ 1...6 ~= $0 }) {
        print("Invalid guess. Enter 4 digits, each from 1 to 6.")
        continue
    }
    
    let result = game.checkGuess(guess: guess)
    print("Result: \(result)")
    
    if result == "BBBB" {
        print("Congratulations! You guessed the code!")
        break
    }
}
