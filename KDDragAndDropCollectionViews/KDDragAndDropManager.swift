//
//  KDDragAndDropManager.swift
//  KDDragAndDropCollectionViews
//
//  Created by Michael Michailidis on 10/04/2015.
//  Copyright (c) 2015 Karmadust. All rights reserved.
//

import UIKit

@objc protocol KDDraggable {
    func canDragAtPoint(point : CGPoint) -> Bool
    func representationImageAtIndexPath(indexPath : NSIndexPath) -> UIImageView
    func dataItemAtIndexPath(indexPath : NSIndexPath) -> AnyObject
}

@objc protocol KDDroppable {
    func canDropAtRect(rect : CGRect) -> Bool
    func willMoveItemInRect(item : AnyObject, rect : CGRect) -> Void
    func didMoveItemInRect (item : AnyObject, rect : CGRect) -> Void
    func didMoveItemOut(item : AnyObject) -> Void
    func dropDataItemAtRect(item : AnyObject, rect : CGRect) -> Void
}

class KDDragAndDropManager: NSObject, UIGestureRecognizerDelegate {
    
    private var canvas : UIView = UIView()
    private var collectionViews : [UICollectionView] = []
    private var longPressGestureRecogniser = UILongPressGestureRecognizer()
    
    
    struct Bundle {
        var offset : CGPoint = CGPointZero
        var indexPath : NSIndexPath
        var sourceCollectionView : UICollectionView
        var overCollectionView : UICollectionView?
        var representationImageView : UIView
        var dataItem : AnyObject
    }
    var bundle : Bundle?
    
    init(canvas : UIView, collectionViews : [UICollectionView]) {
        
        super.init()
        
        self.canvas = canvas
        
        self.longPressGestureRecogniser.delegate = self
        self.longPressGestureRecogniser.addTarget(self, action: "updateForLongPress")
        
        self.canvas.addGestureRecognizer(self.longPressGestureRecogniser)
        self.collectionViews = collectionViews
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        for cv in self.collectionViews {
            
            if cv is KDDraggable {
                
                let pointOnCanvas = touch.locationInView(self.canvas)
                
                let collectionViewFrameOnCanvas = self.canvas.convertRect(cv.frame, fromView: cv)
                
                if CGRectContainsPoint(collectionViewFrameOnCanvas, pointOnCanvas) {
                    
                    if let indexPath = cv.indexPathForItemAtPoint(pointOnCanvas) { // if we are actually pressing on a cell
                        
                        let representation = (cv as KDDraggable).representationImageAtIndexPath(indexPath)
                        
                        representation.frame = self.canvas.convertRect(representation.frame, fromView: cv)
                        
                        let offset = CGPointMake(pointOnCanvas.x - representation.frame.origin.x, pointOnCanvas.y - representation.frame.origin.x)
                        
                        let dataItem : AnyObject = (cv as KDDraggable).dataItemAtIndexPath(indexPath)
                        
                        self.bundle = Bundle(
                            offset: offset,
                            indexPath: indexPath,
                            sourceCollectionView: cv,
                            overCollectionView : (cv is KDDroppable ? cv : nil),
                            representationImageView: representation,
                            dataItem : dataItem
                        )
                        
                    } // if let indexPath ...
                    
                    
                } // if CGRectContainsPoint...
                
                println("\(bundle)")
            }
            
            
        }
        
        return (self.bundle != nil)
        
    }
    
    
    func updateForLongPress(recogniser : UILongPressGestureRecognizer) -> Void {
        
        if let bundl = self.bundle {
            
            let pointOnCanvas = recogniser.locationInView(recogniser.view)
            
            switch recogniser.state {
                
                
            case .Began :
                self.canvas.addSubview(bundl.representationImageView)
                
                
            case .Changed :
                
                // Update the frame of the representation image
                var repImgFrame = bundl.representationImageView.frame
                repImgFrame.origin = CGPointMake(pointOnCanvas.x - bundl.offset.x, pointOnCanvas.y - bundl.offset.y);
                bundl.representationImageView.frame = repImgFrame
                
                var overlappingArea : CGFloat = 0.0
                
                var dominantCollectionView : UICollectionView?
                
                for cv in self.collectionViews {
                 
                    if cv is KDDroppable {
                        
                        let collectionViewFrameOnCanvas = self.canvas.convertRect(cv.frame, fromView: cv)
                        
                        // Figure out which collection view is most of the image over
                        var intersectionNew = CGRectIntersection(bundl.representationImageView.frame, collectionViewFrameOnCanvas).size
                        
                        if (intersectionNew.width * intersectionNew.height) > overlappingArea {
                            
                            overlappingArea = intersectionNew.width * intersectionNew.width
                            
                            dominantCollectionView = cv
                        }
                        
                    }
                    
                }
                
                // If we found something then send messages
                if let currentDroppable : KDDroppable = dominantCollectionView? as? KDDroppable {
                    
                    if bundl.overCollectionView != dominantCollectionView {
                        
                        currentDroppable.willMoveItemInRect(bundl.dataItem, rect: bundl.representationImageView.frame)
                        
                        self.bundle!.overCollectionView = dominantCollectionView
                        
                    }
                    
                    currentDroppable.didMoveItemInRect(bundl.dataItem, rect: bundl.representationImageView.frame)
                    
                }
                
                
                
            case .Ended :
                bundl.representationImageView.removeFromSuperview()
                
            default:
                break
                
            }
            
            
        } // if let bundl = self.bundle ...
        
        
        
    }
   
}
