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
    
    var refresh = UIRefreshControl()
    
    enum SectionName: String {
        case pendingInvitations = "Pending Invitations to Games"
        case waitingForResponses = "Waiting for Responses"
        case games = "Active Games"
        case finishedGames = "Finished Games"
    }
    
    var dataSource: [(name: SectionName, data: [Game])] {
        var arrays = [(SectionName, [Game])]()
        
        guard let currentUser = UserController.shared.currentUser,
            let currentGames = GameController.shared.currentGames
            else { return arrays }
        
        let unstartedGames = currentGames.filter { $0.gameStatus == .waitingForPlayers }
        let pendingInvitations = unstartedGames.filter { $0.getStatus(of: currentUser) == .invited }
        let waitingForResponse = unstartedGames.filter { $0.getStatus(of: currentUser) != .invited }
        let activeGames = currentGames.filter { $0.gameStatus != .waitingForPlayers && $0.gameStatus != .gameOver }
        let finishedGames = currentGames.filter { $0.gameStatus == .gameOver }
        
        if pendingInvitations.count > 0 { arrays.append((name: .pendingInvitations, data: pendingInvitations)) }
        if waitingForResponse.count > 0 { arrays.append((name: .waitingForResponses, data: waitingForResponse)) }
        arrays.append((name: .games, data: activeGames))
        if finishedGames.count > 0 { arrays.append((name: .finishedGames, data: finishedGames)) }
        
        return arrays
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setUpViews()
        
        // Load the data, if it hasn't been loaded already
        if GameController.shared.currentGames == nil { loadAllData() }
        
        // Set up the observer to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: .updateListOfGames, object: nil)
        
        // Set up the observers to listen for responses to push notifications
        setUpObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .updateListOfGames, object: nil)
        removeObservers()
    }
    
    // MARK: - Helper Methods
    
    @objc func updateData() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    @objc func refreshData() {
        DispatchQueue.main.async {
            self.loadAllData()
            self.refresh.endRefreshing()
        }
    }
    
    func setUpViews() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .background
        
        // Set up the refresh icon to check for updates whenever the user pulls down on the tableview
        refresh.attributedTitle = NSAttributedString(string: "Checking for updates")
        refresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refresh)
    }
    
    func loadAllData() {
        // Show the loading icon
        view.startLoadingIcon()
        
        GameController.shared.fetchCurrentGames { [weak self] (result) in
            DispatchQueue.main.async {
                // Hide the loading icon
                self?.view.stopLoadingIcon()
                
                switch result {
                case .success(_):
                    // Refresh the table to show the data
                    self?.tableView.reloadData()
                case .failure(let error):
                    // Print and display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
    
    func quit(_ game: Game) {
        // Don't allow the user to interact with the view while the change is being processed
        tableView.isUserInteractionEnabled = false
        
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
    
    func leave(_ game: Game) {
        // Don't allow the user to interact with the view while the change is being processed
        tableView.isUserInteractionEnabled = false
        
        GameController.shared.leave(game) { [weak self] (result) in
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if dataSource[indexPath.section].name == .games && dataSource[indexPath.section].data.count > 0 { return true }
        if dataSource[indexPath.section].name == .finishedGames { return true }
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the reference to the game
            let gameToQuit = dataSource[indexPath.section].data[indexPath.row]
            
            // If the game is already over, allow the user to delete it without confirming
            if gameToQuit.gameStatus == .gameOver {
                leave(gameToQuit)
            }
            else {
                // Otherwise, present an alert to confirm the user really wants to quit the game
                presentConfirmAlert(title: "Are you sure?", message: "Are you sure you want to quit the game you're playing with \(gameToQuit.listOfPlayerNames)?") {
                    
                    // If the user clicks "confirm," quit the game and remove it from the tableview
                    self.quit(gameToQuit)
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
        
//        transitionToStoryboard(named: enter_name_here, with: game)
        // BETH: comment out lines 222-244 and uncomment out the above line with whatever storyboard you want to test
        
        // Go to the correct page of the gameplay based on the status of the game and whether or not the user is the lead player
        switch game.gameStatus {
        case .waitingForPlayers:
            transitionToStoryboard(named: .Waiting, with: game)
        case .waitingForDrawing:
            if (game.leadPlayerID == currentUser.recordID) {
                transitionToStoryboard(named: .Drawing, with: game)
            }
            else {
                transitionToStoryboard(named: .Waiting, with: game)
            }
        case .waitingForCaptions:
            if (game.leadPlayerID == currentUser.recordID) || game.getStatus(of: currentUser) == .sentCaption {
                transitionToStoryboard(named: .Waiting, with: game)
            } else {
                transitionToStoryboard(named: .AddCaption, with: game)
            }
        case .waitingForResult:
            transitionToStoryboard(named: .ViewResults, with: game)
        case .waitingForNextRound:
            transitionToStoryboard(named: .Waiting, with: game)
        case .gameOver:
            transitionToStoryboard(named: .GameOver, with: game)
        }
    }
}

// MARK: - TableViewCell Button Delegate

extension GamesListTableViewController: GameTableViewCellDelegate {
    
    func respondToGameInvitation(for cell: GameTableViewCell, accept: Bool) {
        // Make sure the user is connected to the internet
        guard Reachability.checkReachable() else {
            presentInternetAlert()
            return
        }
        
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
                    if accept { self?.transitionToStoryboard(named: .Waiting, with: game) }
                case .failure(let error):
                    // Otherwise, display the error
                    print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                    cell.contentView.stopLoadingIcon()
                    self?.presentErrorAlert(error)
                }
            }
        }
    }
}
