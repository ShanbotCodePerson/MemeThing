//
//  DrawingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController, HasGameObject {
    
    // MARK: - Outlets
    
    @IBOutlet weak var canvasView: CanvasView!
    
    // MARK: - Properties
    
    var game: Game?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Set Up UI
    
    // MARK: - Actions
    
    @IBAction func mainMenuButtonTapped(_ sender: UIBarButtonItem) {
        transitionToStoryboard(named: StoryboardNames.mainMenu)
    }
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        
    }
}
