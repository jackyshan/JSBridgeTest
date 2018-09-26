//
//  ViewController.swift
//  JSBridgeTest
//
//  Created by jackyshan on 2018/9/26.
//  Copyright © 2018年 GCI. All rights reserved.
//

import UIKit

class ViewController: JWebViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let userInfo = ["name": "wb", "sex": "male", "phone": "12333434"]
        let jsonData = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
        let jsonText = String.init(data: jsonData!, encoding: String.Encoding.utf8)
        
        //添加getUserInfo脚本，返回用户信息
        addSyncJSFunc(functionName: "getUserInfo", parmers: [jsonText!])
        
        //添加shareAction脚本，获得分享参数
        addAsyncJSFunc(functionName: "shareAction", parmers: ["name", "sex", "phone", "shareBack"]) { [weak self] (dict) in
            print(dict["name"]!)
            print(dict["sex"]!)
            print(dict["phone"]!)
            
            //执行shareBack脚本，告诉H5分享结果
            self?.actionJsFunc(functionName: dict["shareBack"] as! String, pars: [true as AnyObject], completionHandler: nil)
        }
        
        //开始加载H5
        startUrl(URL.init(string: "http://192.168.2.1/js.html")!)
        
    }
    
}

