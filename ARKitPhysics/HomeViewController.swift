//
//  HomeViewController.swift
//  ARKitPhysics
//
//  Created by mac126 on 2018/4/18.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startAR(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "ARMain", bundle: nil)
        let arVC = storyboard.instantiateInitialViewController()!
        self.show(arVC, sender: nil)
    }
    
    

//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
