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
    
    @IBOutlet weak var canvasView: UIView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
    // MARK: - Properties
    
    var lastPoint = CGPoint.zero
    var swiped = false
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func undoButtonTapped(_ sender: UIButton) {
    }
    
    @IBAction func sentButtonTapped(_ sender: UIButton) {
    }
    
    // MARK: - Drawing Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        swiped = false
        lastPoint = touch.location(in: canvasView)
        print("got here to \(#function) and last point is \(lastPoint)")
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        print("got here to \(#function)")
       
        UIGraphicsBeginImageContext(canvasView.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawingImageView.image?.draw(in: canvasView.bounds)
        
        context.move(to: fromPoint)
        context.addLine(to: toPoint)
        
        context.setLineCap(.round)
        context.setBlendMode(.normal)
        context.setLineWidth(10.0)
        context.setStrokeColor(UIColor.black.cgColor)
        
        context.strokePath()
        
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        print("got here to \(#function) and last point is \(lastPoint)")
        swiped = true
        let currentPoint = touch.location(in: canvasView)
        drawLine(from: lastPoint, to: currentPoint)
        
        lastPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("got here to \(#function) and swiped is \(swiped) and last point is \(lastPoint)")
        if !swiped { drawLine(from: lastPoint, to: lastPoint) }
    }
}
