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
        
        let unstartedGames = currentGames.filter { !$0.allPlayersResponded }
        let pendingInvitations = unstartedGames.filter { $0.leadPlayer == currentUser.reference }
        let waitingForResponse = unstartedGames.filter { $0.leadPlayer == currentUser.reference }
        let activeGames = currentGames.filter { $0.allPlayersResponded }
        
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
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .lightGray
        
        // Load the data, if it hasn't been loaded already
        loadData()
        
        // Set up the observer to listen for notifications telling the view to reload its data
        NotificationCenter.default.addObserver(self, selector: #selector(updateData), name: updateListOfGames, object: nil)
    }
    
    // MARK: - Helper Methods
    
    @objc func updateData() {
        DispatchQueue.main.async { self.tableView.reloadData() }
    }
    
    func loadData() {
        if GameController.shared.currentGames == nil {
            GameController.shared.fetchCurrentGames { [weak self] (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        // Refresh the table to show the data
                        self?.tableView.reloadData()
                    case .failure(let error):
                        // TODO: - better error handling
                        print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
                        self?.presentErrorToUser(error)
                    }
                }
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
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if dataSource[indexPath.section].name == .games { return true }
        return false
    }

   override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // TODO: - present alert to confirm quitting game
            
            // Delete the row from the data source
//            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Navigation
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard dataSource[indexPath.section].name == .games,
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
            print("need to create an end of round view")
        case .gameOver:
            print("need to create a game over view")
        }
    }
}
