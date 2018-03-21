//
//  ScreenshotViewController.swift
//  LogFileViewer//  Created by Mohankumar on 03/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class ScreenshotViewController: UIViewController {
    @IBOutlet weak var imageContainerView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    var images : [UIImage] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareScrollView()
        // Do any additional setup after loading the view.
    }

    func prepareScrollView(){
        var width : CGFloat = 0
        var height : CGFloat = 0
        
        for image in images{
            let imageView = UIImageView.init(frame: CGRect.init(origin: CGPoint.init(x:width,y:0), size: image.size))
            imageView.image = image
            self.imageContainerView?.addSubview(imageView)
            width = width + image.size.width
            if image.size.height > height {
                height = image.size.height
            }
        }
        self.imageContainerView?.frame = CGRect.init(origin: CGPoint.init(x:0,y:0), size: CGSize.init(width: width, height: height))
        scrollView.contentSize = self.imageContainerView.frame.size
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareScreeshot(_ sender: UIButton) {
        let image = screenshot()
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let filename = "Screenshot"
        DispatchQueue.main.async {
            if let imageData = UIImageJPEGRepresentation(image, 1.0){
                let imageUrl = documentDirectoryUrl.appendingPathComponent("\(filename.components(separatedBy: "/").last ?? filename).jpg")
                print(imageUrl)
                do{
                    try imageData.write(to:imageUrl, options: [])
                    
                }
                catch let error{
                    print("exception",error.localizedDescription)
                }
                  let objectsToShare = [imageUrl]
                            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = sender
                activityVC.popoverPresentationController?.sourceRect = sender.bounds
                
                self.present(activityVC, animated: true, completion: nil)
            }
            else{
                print("Error in screenshot")
            }
        }

        
        //        jsonViewParams.screenshot = image
    }
    
    func screenshot() -> UIImage{
        UIGraphicsBeginImageContextWithOptions(self.scrollView.contentSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        let previousFrame = scrollView.frame
        scrollView.frame = CGRect.init(x: scrollView.frame.origin.x, y: scrollView.frame.origin.y, width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height);
        scrollView.layer.render(in: context!)
        scrollView.frame = previousFrame
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return image!
    }
    

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
