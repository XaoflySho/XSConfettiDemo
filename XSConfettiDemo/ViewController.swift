//
//  ViewController.swift
//  XSConfettiDemo
//
//  Created by 邵晓飞 on 2022/1/11.
//

import UIKit

class ViewController: UIViewController {

    var confettiView: XSConfettiView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let confettiView = XSConfettiView(frame: self.view.bounds)
        confettiView.clipsToBounds = true
        self.confettiView = confettiView
        self.view.addSubview(confettiView)
    }

    @IBAction func buttonClick(_ sender: UIButton) {
        confettiView?.startAnimating()
    }
}

