//
//  DrawingViewController.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/28/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class DrawingViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var canvasView: CanvasView!
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
        canvasView.undoDraw()
    }
    
    @IBAction func sentButtonTapped(_ sender: UIButton) {
    }
}
