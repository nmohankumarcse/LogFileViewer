//
//  File.swift
//  LogFileViewer//  Created by Mohankumar on 27/02/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

extension UIImage {
      
    typealias RectCalculationClosure = (_ parentSize: CGSize, _ newImageSize: CGSize)->(CGRect)
    
    func with(image named: String, rectCalculation: RectCalculationClosure) -> UIImage {
        return with(image: UIImage(named: named), rectCalculation: rectCalculation)
    }
    
    func with(image: UIImage?, rectCalculation: RectCalculationClosure) -> UIImage {
        
        if let image = image {
            UIGraphicsBeginImageContext(size)
            
            draw(in: CGRect(origin: .zero, size: size))
            image.draw(in: rectCalculation(size, image.size))
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }
        return self
    }
}

extension UIImageView {
    
    enum ImageAddingMode {
        case changeOriginalImage
        case addSubview
    }
    
    func drawOnCurrentImage(anotherImage: UIImage?, mode: ImageAddingMode, rectCalculation: UIImage.RectCalculationClosure) {
        
        guard let image = image else {
            return
        }
        
        switch mode {
        case .changeOriginalImage:
            self.image = image.with(image: anotherImage, rectCalculation: rectCalculation)
            
        case .addSubview:
            let newImageView = UIImageView(frame: rectCalculation(frame.size, image.size))
            newImageView.image = anotherImage
            addSubview(newImageView)
        }
    }
}
