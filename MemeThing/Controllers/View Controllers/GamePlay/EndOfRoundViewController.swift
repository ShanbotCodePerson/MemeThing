//
//  EndOfRoundViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/12/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

// MARK: - Protocol

protocol EndOfRoundViewControllerDelegate: class {
    func closeEndOfRoundView()
}

class EndOfRoundViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var winnerLabel: UILabel!
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    weak var delegate: EndOfRoundViewControllerDelegate?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Fetch the meme
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Set the image view
                    self?.memeImageView.image = meme.photo
                    
                    // Fetch the winning caption
                    MemeController.shared.fetchWinningCaption(for: meme) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let caption):
                                // Set the text of the caption label
                                self?.captionLabel.text = caption.text
                                
                                // Get the name of the user from the game object to display in the winner's name label
                                let name = game.getName(of: caption.author)
                                self?.winnerLabel.text = "Congratulations \(name) for having the best caption!"
                                
                                // TODO: - don't need subscriptions to captions, just handle points here?
                                
                            case .failure(let error):
                                // Print and display the error
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            }
                        }
                    }
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
        delegate?.closeEndOfRoundView()
        dismiss(animated: true)
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        delegate?.closeEndOfRoundView()
        dismiss(animated: true)
    }
}
