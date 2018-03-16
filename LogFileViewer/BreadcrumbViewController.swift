//
//  BreadcrumbViewController.swift
//  LogFileViewer//  Created by Mohankumar on 02/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class BreadcrumbViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var breadCrumbCollectionView: UICollectionView!
    var selectedIndexHandler : ((_ index: Int)->())?
    var breadCrumb : [String] = []
    var indexSelected : Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refresh()
        // Do any additional setup after loading the view.
    }
    
    func refresh(){
        self.breadCrumbCollectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if self.breadCrumb.count > 0{
                self.breadCrumbCollectionView.scrollToItem(at: IndexPath.init(row: self.indexSelected, section: 0), at: .left, animated: true)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return breadCrumb.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell : BreadcrumbCollectionViewCell = self.breadCrumbCollectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! BreadcrumbCollectionViewCell
        cell.headingLabel.text = "<\(self.breadCrumb[indexPath.item])"
        cell.headingLabel.textColor = UIColor.darkGray
        if indexPath.item == indexSelected{
            cell.headingLabel.textColor = UIColor.blue
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.breadCrumb[indexPath.item].width(withConstrainedHeight: 50, font: UIFont.systemFont(ofSize: 17))
        return CGSize.init(width: width+30, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let hasCompletionHandler = self.selectedIndexHandler{
            hasCompletionHandler(indexPath.item)
        }
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
