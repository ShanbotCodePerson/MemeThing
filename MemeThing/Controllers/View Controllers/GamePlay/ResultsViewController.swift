//
//  ResultsViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController, HasAGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var chooseWinnerButton: UIButton!
    
    // MARK: - Properties
    
    var game: Game?
    var meme: Meme? { didSet { memeImageView.image = meme?.photo } }
    var captions: [Caption]? { didSet { setUpPages(from: captions) } }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load all the data, if it hasn't been loaded already
        loadAllData()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toNewRound, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Helper Method
    
    func loadAllData() {
        guard let game = game, let memeReference = game.memes?.last else { return }
        
        // Fetch the meme from the cloud
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Save the meme
                    self?.meme = meme
                    
                    // TODO: - nested completions
                    
                    // Fetch the captions for that meme from the cloud
                    MemeController.shared.fetchCaptions(for: meme) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let captions):
                                // Save the captions
                                self?.captions = captions
                                self?.pageControl.numberOfPages = captions.count
                            case .failure(let error):
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorToUser(error)
                            }
                        }
                    }
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorToUser(error)
                }
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game, let currentUser = UserController.shared.currentUser else { return }
        
        // Hide the button to choose the winner if the user is not the lead player
        if game.leadPlayer != currentUser.reference {
            chooseWinnerButton.isHidden = true
        }
    }
    
    func setUpPages(from captions: [Caption]?) {
        guard let captions = captions else { return }
        
        var frame = CGRect.zero
        
        for index in 0..<captions.count {
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            
            let captionLabel = MemeThingLabel(frame: frame)
            captionLabel.text = captions[index].text
            
            self.scrollView.addSubview(captionLabel)
        }
        
        scrollView.contentSize = CGSize(width: (scrollView.frame.size.width * CGFloat(captions.count)), height: scrollView.frame.size.height)
        scrollView.delegate = self
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        // Transition to the relevant view based on the type of update
        DispatchQueue.main.async {
            if sender.name == toNewRound {
                if game.leadPlayer == currentUser.reference {
                    self.transitionToStoryboard(named: StoryboardNames.drawingView, with: game)
                } else {
                    self.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                } // FIXME: - fix navigation for one who just became lead player when game reset
            }
            else if sender.name == toGameOver {
                self.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        print("got here")
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        transitionToStoryboard(named: StoryboardNames.leaderboardView, with: game)
    }
    
    @IBAction func chooseWinnerButtonTapped(_ sender: UIButton) {
        guard let game = game, let meme = meme, let captions = captions else { return }
        
        // Get the caption based on which "page" the view is on at the time the button is clicked
        let caption = captions[pageControl.currentPage]
        
        // Update the data in the meme and the caption
        MemeController.shared.setWinningCaption(to: caption, for: meme) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // TODO: - nested completions
                    
                    // Increment the points of the player who wrote that caption and update the game's status based on whether there is an overall winner or not
                    game.winningCaptionSelected(as: caption)
                    game.resetGame()
                    
                    // Save the updated game to the cloud
                    GameController.shared.saveChanges(to: game) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                // Navigate back to the waiting view if a new round is starting, or the game over page
                                if game.gameStatus == .gameOver {
                                    self?.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
                                } else {
                                    self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                                } // FIXME: - fix navigation for one who just became lead player
                            case .failure(let error):
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorToUser(error)
                            }
                        }
                    }
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorToUser(error)
                }
            }
        }
    }
}

// MARK: - Scroll View Delegate

extension ResultsViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(pageNumber)
    }
}
