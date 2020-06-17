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
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var constraintToButton: NSLayoutConstraint!
    @IBOutlet weak var constraintToSafeArea: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var gameID: String?
    var game: Game? { GameController.shared.currentGames?.first(where: { $0.recordID.recordName == gameID }) }
    var meme: Meme? { didSet { memeImageView.image = meme?.photo } }
    var captions: [Caption]? { didSet { setUpPages(from: captions) } }
    var nextDestination: String?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load all the data
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
        print("got here to \(#function) and \(game.debugging)")
        
        // Fetch the meme from the cloud
        MemeController.shared.fetchMeme(from: memeReference) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let meme):
                    // Save the meme
                    self?.meme = meme
                    print("in completion and meme id is \(meme.reference.recordID.recordName) with \(String(describing: meme.captions?.count)) captions")
                    
                    // Fetch the captions for that meme from the cloud
                    MemeController.shared.fetchCaptions(for: meme) { (result) in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let captions):
                                print("in second completion and captions are \(captions)")
                                // Save the captions
                                print("captions were set")
                                self?.captions = captions
                                self?.pageControl.numberOfPages = captions.count
                            case .failure(let error):
                                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                self?.presentErrorAlert(error)
                            }
                        }
                    }
                case .failure(let error):
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    // MARK: - Set Up UI
    
    func setUpViews() {
        view.backgroundColor = .background
        loadingIndicator.isHidden = true
        previousButton.deactivate()
        previousButton.tintColor = .lightGray
        
        guard let game = game, let currentUser = UserController.shared.currentUser else { return }
        
        // Hide the button to choose the winner if the user is not the lead player
        if game.leadPlayer != currentUser.reference {
            chooseWinnerButton.isHidden = true
            constraintToButton.isActive = false
            constraintToSafeArea.isActive = true
        }
    }
    
    func setUpPages(from captions: [Caption]?) {
        print("setting up scroll view")
        guard let captions = captions else { return }
        print("got here to \(#function) and \(captions.count) captions have loaded")
        
        var frame = CGRect.zero
        
        for index in 0..<captions.count {
            frame.origin.x = scrollView.frame.size.width * CGFloat(index)
            frame.size = scrollView.frame.size
            
            let captionLabel = MemeThingCaption(frame: frame)
            captionLabel.text = captions[index].text
            captionLabel.textAlignment = .center
            captionLabel.setUpViews()
            captionLabel.addBorder()
            
            self.scrollView.addSubview(captionLabel)
        }
        
        scrollView.contentSize = CGSize(width: (scrollView.frame.size.width * CGFloat(captions.count)), height: scrollView.frame.size.height)
        scrollView.delegate = self
    }
    
    // Helper method to enable and disable the previous and next buttons as necessary
    func resetButtons() {
        if pageControl.currentPage == 0 {
            previousButton.deactivate()
            previousButton.tintColor = .lightGray
        } else {
            previousButton.activate()
            previousButton.tintColor = .systemBlue
        }
        if pageControl.currentPage == (pageControl.numberOfPages - 1) {
            nextButton.deactivate()
            nextButton.tintColor = .lightGray
        } else {
            nextButton.activate()
            nextButton.tintColor = .systemBlue
        }
    }
    
    // Helper methods to disable the UI while the data is loading and reenable it when it's finished
    func disableUI() {
        // Display the loading icon while the image saves
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        
        // Don't allow the user to interact with the screen while the save is in progress
        chooseWinnerButton.deactivate()
        nextButton.deactivate()
        nextButton.tintColor = .lightGray
        previousButton.deactivate()
        previousButton.tintColor = .lightGray
    }
    
    func enableUI() {
        // Hide the loading icon
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        
        // Re enable the buttons as applicable
        chooseWinnerButton.activate()
        if pageControl.currentPage < pageControl.numberOfPages {
            nextButton.activate()
            nextButton.tintColor = .systemBlue // TODO: - do I want a different color for this?
        }
        if pageControl.currentPage > 0 {
            previousButton.activate()
            previousButton.tintColor = .systemBlue
        }
    }
    
    // MARK: - Respond to Notifications
    
    @objc func transitionToNewPage(_ sender: NSNotification) {
        // Only change the view if the update is for the game that the user currently has open
        guard let game  = game, let gameID = sender.userInfo?["gameID"] as? String,
            gameID == game.recordID.recordName,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        // Decide on the next destination view controller based on the type of update
        DispatchQueue.main.async {
            if sender.name == toNewRound {
                if game.leadPlayer == currentUser.reference {
                    self.nextDestination = StoryboardNames.drawingView
                } else {
                    self.nextDestination = StoryboardNames.waitingView
                }
            }
            else if sender.name == toGameOver {
                self.nextDestination = StoryboardNames.gameOverView
            }
            
            // Before transitioning to the next view, first show everyone the results of this round
            self.presentEndOFRoundView(with: game)
        }
    }
    
    // A helper function to set up and present the end of round view
    func presentEndOFRoundView(with game: Game) {
        let storyboard = UIStoryboard(name: StoryboardNames.endOfRoundView, bundle: nil)
        guard let initialVC = storyboard.instantiateInitialViewController() as? EndOfRoundViewController else { return }
        initialVC.gameID = game.recordID.recordName
        initialVC.nextDestination = self.nextDestination
        initialVC.modalPresentationStyle = .overFullScreen
        initialVC.modalTransitionStyle = .crossDissolve
        self.present(initialVC, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func dotsButtonTapped(_ sender: UIBarButtonItem) {
        guard let game = game else { return }
        presentPopoverStoryboard(named: StoryboardNames.leaderboardView, with: game)
    }
    
    @IBAction func chooseWinnerButtonTapped(_ sender: UIButton) {
        guard let game = game, let meme = meme, let captions = captions else { return }
        
        // Get the caption based on which "page" the view is on at the time the button is clicked
        let caption = captions[pageControl.currentPage]
        
        // Disable the UI while the data loads
        disableUI()
        
        // Update the data in the meme and the caption
        MemeController.shared.setWinningCaption(to: caption, for: meme) { [weak self] (result) in
            switch result {
            case .success(_):
                // Reset the game for another round
                game.resetGame()
                
                // Increment the points of the player who wrote that caption and update the game's status based on whether there is an overall winner or not
                game.winningCaptionSelected(as: caption)
                
                // Save the updated game to the cloud
                GameController.shared.saveChanges(to: game) { (result) in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(_):
                            // If the game is over, delete it from the cloud and go to the game over view
                            if game.gameStatus == .gameOver {
                                GameController.shared.delete(game) { (result) in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(_):
                                            // Set the next destination as the game over view
                                            self?.nextDestination = StoryboardNames.gameOverView
                                            
                                            // Before transitioning to the next view, first display the results of this round
                                            self?.loadingIndicator.stopAnimating()
                                            self?.presentEndOFRoundView(with: game)
                                        case .failure(let error):
                                            // Print and display the error
                                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                                            self?.presentErrorAlert(error)
                                            
                                            // Reset the UI
                                            self?.enableUI()
                                        }
                                    }
                                }
                            } else {
                                // Otherwise, set the next destination as the waiting view
                                self?.nextDestination = StoryboardNames.waitingView
                                
                                // Before transitioning to the next view, first display the results of this round
                                self?.loadingIndicator.stopAnimating()
                                self?.presentEndOFRoundView(with: game)
                            }
                        case .failure(let error):
                            // Print and display the error
                            print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                            self?.presentErrorAlert(error)
                            
                            // Reset the UI
                            self?.enableUI()
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                    
                    // Reset the UI
                    self?.enableUI()
                }
            }
        }
    }
    
    @IBAction func previousButtonTapped(_ sender: UIButton) {
        guard let captions = captions, captions.count > 1 else { return }
        if pageControl.currentPage > 0 {
            pageControl.currentPage -= 1
            UIView.animate(withDuration: 0.2) {
                self.scrollView.contentOffset.x = self.scrollView.contentSize.width * CGFloat((Double(self.pageControl.currentPage) / Double(self.pageControl.numberOfPages)))
            }
            
            // Activate or deactivate the previous and next buttons as needed
            resetButtons()
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        guard let captions = captions, captions.count > 1 else { return }
        if pageControl.currentPage < pageControl.numberOfPages {
            pageControl.currentPage += 1
            UIView.animate(withDuration: 0.2) {
                self.scrollView.contentOffset.x = self.scrollView.contentSize.width * CGFloat((Double(self.pageControl.currentPage) / Double(self.pageControl.numberOfPages)))
            }
            
            // Activate or deactivate the previous and next buttons as needed
            resetButtons()
        }
    }
}

// MARK: - Scroll View Delegate

extension ResultsViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width
        pageControl.currentPage = Int(pageNumber)
        
        // Activate or deactivate the previous and next buttons as needed
        resetButtons()
    }
}
