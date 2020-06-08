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
    var meme: Meme?
    var captions: [Caption]?
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Set up the observers to listen for notifications telling the view to transition to a new page
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toNewRound, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transitionToNewPage(_:)), name: toGameOver, object: nil)
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        guard let game = game, let memeReference = game.memes?.last,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        // Hide the button to choose the winner if the user is not the lead player
        if game.leadPlayer != currentUser.reference {
            chooseWinnerButton.isHidden = true
        }
        
        // Fetch the meme object and fill out the image view
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    self?.meme = meme
                    self?.memeImageView.image = meme.photo
                    
                    // TODO: - refactor this to a better location
                    // Fetch the list of captions for that meme
                    MemeController.shared.fetchCaptions(for: meme) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let captions):
                                self?.captions = captions
                                self?.pageControl.numberOfPages = captions.count
                                
                                self?.setUpPages(from: captions)
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
    
    func setUpPages(from captions: [Caption]) {
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
                }
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
    
    @IBAction func chooseWinnerButtonTapped(_ sender: UIButton) {
        guard let game = game, let meme = meme, let captions = captions else { return }
        
        // Get the caption based on which "page" the view is on at the time the button is clicked
        let caption = captions[pageControl.currentPage]
        
        // Update the data in the meme and the caption
        MemeController.shared.setWinningCaption(to: caption, for: meme) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // TODO: - refactor this to somewhere else, cleaner
                    
                    // Increment the points of the player who wrote that caption and update the game's status based on whether there is an overall winner or not
                    game.winningCaptionSelected(as: caption)
                    game.resetGame()
                    // FIXME: - where do i update game for a new round?
                    
                    // Save the updated game to the cloud
                    GameController.shared.update(game) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(_):
                                // Navigate back to the waiting view if a new round is starting, or the game over page
                                if game.gameStatus == .gameOver {
                                    self?.transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
                                } else {
                                    self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
                                    // TODO: - not sure if this will work, want to present leaderboard on top of waiting screen
                                    self?.transitionToStoryboard(named: StoryboardNames.leaderboardView, with: game)
                                }
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
