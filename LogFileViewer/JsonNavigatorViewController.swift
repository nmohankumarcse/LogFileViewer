//
//  JsonNavigatorViewController.swift
//  LogFileViewer//  Created by Mohankumar on 02/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class JsonNavigatorViewController: UIViewController {
    var json : Dictionary<String,Any>?
    var heading = "Root"
    var pageIndex : Int = 0
    
    var jsonCollectionViewController : JsonCollectionViewController?
    var breadCrumbViewController : BreadcrumbViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "BreadCrumb"{
            breadCrumbViewController = segue.destination as? BreadcrumbViewController
            breadCrumbViewController?.indexSelected = self.pageIndex
            breadCrumbViewController?.selectedIndexHandler = handleSelectionForBreadcrumb(index:)
        }
        else if segue.identifier == "JsonCollection"{ 
            jsonCollectionViewController = segue.destination as? JsonCollectionViewController
            let jsonViewParam = JsonViewParams.init(list: [json!], filters: [], sortFilters: [], pageIndex: self.pageIndex, selectedIndexPath: nil, collapseSectionArray: [], heading: self.heading,parent : self.heading, tree : "\t->\(self.heading)", color : UIColor.white, parentColor : UIColor.white)
            jsonCollectionViewController?.jsonViewParamsList = [jsonViewParam]
            jsonCollectionViewController?.addBreadCrumbHandler = appendBreadCrumb(index:headings:)
        }
    }
    
    func appendBreadCrumb(index: Int, headings: [String]){
        breadCrumbViewController?.indexSelected = index
        breadCrumbViewController?.breadCrumb = headings
        breadCrumbViewController?.refresh()
        jsonCollectionViewController?.indexSelected = index
        jsonCollectionViewController?.refresh()
    }
    
    func handleSelectionForBreadcrumb(index : Int){
        breadCrumbViewController?.indexSelected = index
        breadCrumbViewController?.refresh()
//        stackViewController?.moveToPage(index: index)
        jsonCollectionViewController?.indexSelected = index
        jsonCollectionViewController?.refresh()
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
