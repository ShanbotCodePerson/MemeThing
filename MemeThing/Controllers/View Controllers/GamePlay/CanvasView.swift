//
//  CanvasView.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/29/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

class CanvasView: UIView {
    
    // MARK: - Properties
    
    var lines: [[CGPoint]] = [[]]
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }
    
    // Some formatting
    func setUpViews() {
        addCornerRadius()
        addBorder()
    }
    
    // MARK: - Drawing Methods
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw each line in the array of lines
        for points in lines {
            // Draw each line by using its array of points
            context.addLines(between: points)
            
            // Set the defaults for the appearance of the line
            context.setLineWidth(10.0)
            context.setLineCap(.round)
            
            // Draw the path
            context.strokePath()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append([CGPoint]())
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first?.location(in: self),
            var lastPoint = lines.popLast()
            else { return }
        
        // Add the new points to the most recent line and save that back to the array
        lastPoint.append(touch)
        lines.append(lastPoint)
        
        // Update the display
        setNeedsDisplay()
    }
    
    // MARK: - Helper Methods
    
    func undoDraw() {
        // Remove the most recent line from the array
        _ = lines.popLast()
        
        // Update the display
        setNeedsDisplay()
    }
    
    func getImage() -> UIImage {
        // Get a snapshot from the view
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, UIScreen.main.scale)
        snapshotView(afterScreenUpdates: true)
        
        // Get the image from the snapshot
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return image
        }
        return UIImage()
    }
}
