//
//  ViewController.swift
//  XSConfettiDemo
//
//  Created by 邵晓飞 on 2022/1/11.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buttonClick(_ sender: UIButton) {
        let confettiView = XSConfettiView(frame: self.view.bounds)
        self.view.addSubview(confettiView)
    }
}

