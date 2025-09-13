import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct GameResponse: Decodable {
    let gameID: String

    enum CodingKeys: String, CodingKey {
        case gameID = "game_id"
    }
}

struct GuessResponse: Decodable {
    let black: Int
    let white: Int
}

class MastermindAPI {
    let baseURL = "https://mastermind.darkube.app"
    var gameID: String?

    func startGame(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/game") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error starting game: \(error?.localizedDescription ?? "unknown error")")
                completion(false)
                return
            }

            do {
                let gameResp = try JSONDecoder().decode(GameResponse.self, from: data)
                self.gameID = gameResp.gameID
                completion(true)
            } catch {
                print("Decoding error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(false)
            }
        }.resume()
    }

    func makeGuess(_ guess: [Int], completion: @escaping (GuessResponse?) -> Void) {
        guard let gameID = gameID, let url = URL(string: "\(baseURL)/guess") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let guessString = guess.map(String.init).joined()
        let body: [String: Any] = ["game_id": gameID, "guess": guessString]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error making guess: \(error?.localizedDescription ?? "unknown error")")
                completion(nil)
                return
            }

            if let errorResp = try? JSONDecoder().decode([String: String].self, from: data),
                let message = errorResp["error"]
            {
                print("Server error: \(message)")
                completion(nil)
                return
            }

            do {
                let guessResp = try JSONDecoder().decode(GuessResponse.self, from: data)
                completion(guessResp)
            } catch {
                print("Decoding error: \(error)")
                print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
                completion(nil)
            }
        }.resume()
    }

    func deleteGame(completion: @escaping (Bool) -> Void) {
        guard let gameID = gameID, let url = URL(string: "\(baseURL)/game/\(gameID)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error deleting game: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let httpResp = response as? HTTPURLResponse,
                (200...299).contains(httpResp.statusCode)
            {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

let api = MastermindAPI()

print("Starting game...")
let semaphore = DispatchSemaphore(value: 0)

api.startGame { success in
    if success {
        print("Game started! GameID: \(api.gameID!)")
    } else {
        print("Failed to start game")
        exit(0)
    }
    semaphore.signal()
}

semaphore.wait()

func endGame() {    
    api.deleteGame { success in
        if success {
            print("Game deleted successfully.")
        } else {
            print("Failed to delete game.")
        }
        exit(0)
    }    
    }
var gameOver = false
while !gameOver {
    print("\nEnter your guess (4 digits 1-6, type 'exit' to quit): ", terminator: "")
    guard let input = readLine() else { continue }
    if input.lowercased() == "exit" {
        gameOver = true
        endGame()

    }

    let guess = input.compactMap { Int(String($0)) }
    let guessSemaphore = DispatchSemaphore(value: 0)
    api.makeGuess(guess) { guessResp in
        if let guessResp = guessResp {
            print("Result: \(guessResp.black) black, \(guessResp.white) white")
            if guessResp.black == 4 {
                print("Congratulations! You guessed the code!")
                gameOver = true
                endGame()
            }
        }
        guessSemaphore.signal()
    }
    guessSemaphore.wait()
}
