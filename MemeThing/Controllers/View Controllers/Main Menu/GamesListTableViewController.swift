//
//  GamesListTableViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/4/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class GamesListTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    enum SectionName: String {
        case pendingInvitations = "Pending Invitations to Games"
        case waitingForResponses = "Waiting for Responses"
        case games = "Active Games"
    }
    
    var dataSource: [(name: SectionName, data: [Game])] {
        var arrays = [(SectionName, [Game])]()
        
        guard let currentUser = UserController.shared.currentUser,
            let currentGames = GameController.shared.currentGames
            else { return arrays }
        
        let unstartedGames = currentGames.filter { $0.gameStatus == .waitingForPlayers }
        let pendingInvitations = unstartedGames.filter { $0.leadPlayer != currentUser.reference }
        let waitingForResponse = unstartedGames.filter { $0.leadPlayer == currentUser.reference }
        let activeGames = currentGames.filter { $0.gameStatus != .waitingForPlayers }
        
        if pendingInvitations.count > 0 {
            arrays.append((name: .pendingInvitations, data: pendingInvitations))
        }
        if waitingForResponse.count > 0 {
            arrays.append((name: .waitingForResponses, data: waitingForResponse))
        }
        arrays.append((name: .games, data: activeGames))
        
        return arrays
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load the data, if it hasn't been loaded already
        loadAllData()
        
        // Set up the observer to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: updateListOfGames, object: nil)
    }
    
    // MARK: - Helper Methods
    
    @objc func updateData() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .background
    }
    
    func loadAllData() {
        if GameController.shared.currentGames == nil {
            GameController.shared.fetchCurrentGames { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the table to show the data
                        self?.tableView.reloadData()
                    case .failure(let error):
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorAlert(error)
                    }
                }
            }
        }
    }
    
    func quitGame(_ game: Game) {
        // Don't allow the user to interact with the view while the change is being processed
        tableView.isUserInteractionEnabled = false // TODO: - this needs to be tested, if it works, need to use in gameplay screens too
        
        GameController.shared.quit(game) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Update the tableview
                    self?.updateData()
                case .failure(let error):
                    // Print and present the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
                // Turn user interaction back on
                self?.tableView.isUserInteractionEnabled = true
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].name.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Add a placeholder row if the user has no active games
        if dataSource[section].name == .games && dataSource[section].data.count == 0 { return 1 }
        return dataSource[section].data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "gameCell", for: indexPath) as? GameTableViewCell else { return UITableViewCell() }
        
        let sectionName = dataSource[indexPath.section].name
        let data = dataSource[indexPath.section].data
        
        // Add a placeholder row if the user has no active games
        if sectionName == .games && data.count == 0 { cell.setUpViews(in: .games, with: nil) }
        else {
            let game = data[indexPath.row]
            cell.setUpViews(in: sectionName, with: game)
            cell.delegate = self
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if dataSource[indexPath.section].name == .games && dataSource[indexPath.section].data.count == 0 { return 50 }
        else if dataSource[indexPath.section].name == .games { return 100 }
        return 120
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if dataSource[indexPath.section].name == .games && dataSource[indexPath.section].data.count > 0 { return true }
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the reference to the game
            let gameToQuit = dataSource[indexPath.section].data[indexPath.row]
            
            // If the game is already over, allow the user to delete it without confirming
            if gameToQuit.gameStatus == .gameOver {
                quitGame(gameToQuit)
            } else {
                // Otherwise, present an alert to confirm the user really wants to quit the game
                presentConfirmAlert(title: "Are you sure?", message: "Are you sure you want to quit the game you're playing with \(gameToQuit.listOfPlayerNames)?") {
                    
                    // If the user clicks "confirm," quit the game and remove it from the tableview
                    self.quitGame(gameToQuit)
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard dataSource[indexPath.section].name != .pendingInvitations,
            dataSource[indexPath.section].data.count > 0,
            let currentUser = UserController.shared.currentUser
            else { return }
        
        // Get the record of the selected game
        let game = dataSource[indexPath.section].data[indexPath.row]
        
        // Go to the correct page of the gameplay based on the status of the game and whether or not the user is the lead player
        switch game.gameStatus {
        case .waitingForPlayers:
            transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
        case .waitingForDrawing:
            if (game.leadPlayer == currentUser.reference) {
                transitionToStoryboard(named: StoryboardNames.drawingView, with: game)
            }
            else {
                transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
            }
        case .waitingForCaptions:
            if (game.leadPlayer == currentUser.reference) || game.getStatus(of: currentUser) == .sentCaption {
                transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
            } else {
                transitionToStoryboard(named: StoryboardNames.captionView, with: game)
            }
        case .waitingForResult:
            transitionToStoryboard(named: StoryboardNames.resultsView, with: game)
        case .waitingForNextRound:
            transitionToStoryboard(named: StoryboardNames.waitingView, with: game)
        case .gameOver:
            transitionToStoryboard(named: StoryboardNames.gameOverView, with: game)
        }
    }
}

// MARK: - TableViewCell Button Delegate

extension GamesListTableViewController: GameTableViewCellDelegate {
    
    func respondToGameInvitation(for cell: GameTableViewCell, accept: Bool) {
        // Get the reference to the game that was responded to
        guard let indexPath = tableView.indexPath(for: cell),
            dataSource[indexPath.section].name == .pendingInvitations
            else { return }
        let game = dataSource[indexPath.section].data[indexPath.row]
        
        // Respond to the game invitation
        GameController.shared.respondToInvitation(to: game, accept: accept) { [weak self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // If the user accepted the invitation, transition them to the waiting view until all users have responded
                    if accept { self?.transitionToStoryboard(named: StoryboardNames.waitingView, with: game) }
                case .failure(let error):
                    // Otherwise, display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
}
