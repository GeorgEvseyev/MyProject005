//
//  ViewController.swift
//  myProject005
//
//  Created by Георгий Евсеев on 13.06.22.
//

import UIKit

class ViewController: UITableViewController {
    var words = Word()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(startGame2))

        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                words.allWords = startWords.components(separatedBy: "\n")
            }
        }

        if words.allWords.isEmpty {
            words.allWords = ["silkworm"]
        }

        let defaults = UserDefaults.standard

        if let savedWord = defaults.object(forKey: "word") as? Data {
            let jsonDecoder = JSONDecoder()

            do {
                words = try jsonDecoder.decode(Word.self, from: savedWord)
            } catch {
                print("Failed to load people")
            }
        }
        startGame()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.usedWords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = words.usedWords[indexPath.row]
        save()
        return cell
    }

    @objc func startGame() {
        title = words.title
    }

    @objc func startGame2() {
        title = words.allWords.randomElement()
        print("\(title!)")
        words.usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        words.title = title!
        print("\(words.title)")
        save()
    }

    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }

        ac.addAction(submitAction)
        present(ac, animated: true)
    }

    func submit(_ answer: String) {
        print(answer)
        let lowerAnswer = answer.lowercased()
        if answer != title?.lowercased() {
            if isPossible(word: lowerAnswer) {
                if isOriginal(word: lowerAnswer) {
                    if isReal(word: lowerAnswer) {
                        words.usedWords.insert(answer, at: 0)

                        let indexPath = IndexPath(row: 0, section: 0)
                        tableView.insertRows(at: [indexPath], with: .automatic)

                        return

                    } else {
                        return showErrorMessage()
                    }
                }
            }
        }

        func isPossible(word: String) -> Bool {
            guard var tempWord = title?.lowercased() else { return false }

            for letter in word {
                if let position = tempWord.firstIndex(of: letter) {
                    tempWord.remove(at: position)
                } else {
                    return false
                }
            }

            return true
        }

        func isOriginal(word: String) -> Bool {
            return !words.usedWords.contains(word)
        }

        func isReal(word: String) -> Bool {
            let checker = UITextChecker()
            let range = NSRange(location: 0, length: word.utf16.count)
            let isUnderThree = Int(range.length)
            if isUnderThree <= 3 {
                return false
            }
            let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")

            return misspelledRange.location == NSNotFound
        }
        func showErrorMessage() {
            let errorTitle: String
            let errorMessage: String
            if isPossible(word: lowerAnswer) {
                if isOriginal(word: lowerAnswer) {
                    if isReal(word: lowerAnswer) {
                        return
                    } else {
                        errorTitle = "Word not recognised"
                        errorMessage = "You can't just make them up, you know!"
                    }
                } else {
                    errorTitle = "Word used already"
                    errorMessage = "Be more original!"
                }
            } else {
                guard let title = title?.lowercased() else { return }
                errorTitle = "Word not possible"
                errorMessage = "You can't spell that word from \(title)"
            }

            let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            print(answer)
        }
    }

    func save() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(words) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "word")
            print("Save word.")
        } else {
            print("Failed to save word.")
        }
    }
}
