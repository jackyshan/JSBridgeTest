//
//  JWebViewController.swift
//  JSBridgeTest
//
//  Created by jackyshan on 2018/9/26.
//  Copyright © 2018年 GCI. All rights reserved.
//

import UIKit
import WebKit

class JWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    private var mAsyncScriptArray:[JKWkWebViewHandler] = []
    private var mSyncScriptArray:[JKWkWebViewHandler] = []
    
    private var wkWebView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    public func startUrl(_ url: URL) {
        let configuretion = WKWebViewConfiguration()
        configuretion.preferences = WKPreferences()
        configuretion.preferences.javaScriptEnabled = true
        configuretion.userContentController = WKUserContentController()
        if self.mAsyncScriptArray.count != 0 || self.mSyncScriptArray.count != 0 {
            // 在载入时就添加JS // 只添加到mainFrame中
            let script = WKUserScript(source: createScript(), injectionTime: .atDocumentStart, forMainFrameOnly: true)
            configuretion.userContentController.addUserScript(script)
        }

        //异步需要回调，所以需要添加handler
        for item in self.mAsyncScriptArray {
            configuretion.userContentController.add(self, name: item.name)
        }
        
        let wkWebView = WKWebView(frame: self.view.bounds, configuration: configuretion)
        wkWebView.uiDelegate = self
        self.view.insertSubview(wkWebView, at: 0)
        let request = URLRequest(url: url)
        wkWebView.load(request)
        self.wkWebView = wkWebView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //释放handler
        for item in self.mAsyncScriptArray {
            wkWebView?.configuration.userContentController.removeScriptMessageHandler(forName: item.name)
            wkWebView?.configuration.userContentController.removeAllUserScripts()
        }
    }
    
    // MARK: - 添加JS
    public func addAsyncJSFunc(functionName: String, parmers: [String], action: @escaping ([String:AnyObject]) -> Void) {
        var obj = self.mAsyncScriptArray.filter { (obj) -> Bool in
            return obj.name == functionName
        }.first
        
        if obj == nil {
            obj = JKWkWebViewHandler()
            obj!.name = functionName
            obj!.parmers = parmers
            obj!.action = action
            self.mAsyncScriptArray.append(obj!)
        }
    }

    public func addSyncJSFunc(functionName: String, parmers: [String]) {
        var obj = self.mSyncScriptArray.filter { (obj) -> Bool in
            return obj.name == functionName
            }.first
        
        if obj == nil {
            obj = JKWkWebViewHandler()
            obj!.name = functionName
            obj!.parmers = parmers
            self.mSyncScriptArray.append(obj!)
        }
    }
    
    // MARK: - 插入JS
    private func createScript() -> String {
        var result = "iOSApp = {"
        for item in self.mAsyncScriptArray {
            let pars = createParmes(dict: item.parmers)
            let str = "\"\(item.name!)\":function(\(pars)){window.webkit.messageHandlers.\(item.name!).postMessage([\(pars)]);},"
            result += str
        }
        for item in self.mSyncScriptArray {
            let pars = createParmes(dict: item.parmers)
            let str = "\"\(item.name!)\":function(){return JSON.stringify(\(pars));},"
            result += str
        }
        result = (result as NSString).substring(to: result.count - 1)
        result += "}"
        print("++++++++\(result)")
        return result
    }
    
    private func createParmes(dict: [String]) -> String {
        var result = ""
        for key in dict {
            result += key + ","
        }
        if result.count > 0 {
            result = (result as NSString).substring(to: result.count - 1)
        }
        return result
    }

    // MARK: - 执行JS
    public func actionJsFunc(functionName: String, pars: [AnyObject], completionHandler: ((Any?, Error?) -> Void)?) {
        var parString = ""
        for par in pars {
            parString += "\(par),"
        }
        
        if parString.count > 0 {
            parString = (parString as NSString).substring(to: parString.count - 1)
        }
        
        let function = "\(functionName)(\(parString));"
        wkWebView?.evaluateJavaScript(function, completionHandler: completionHandler)
    }

    // MARK: - WKUIDelegate
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: { (_) -> Void in
            // We must call back js
            completionHandler()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        let funcObjs = self.mAsyncScriptArray.filter { (obj) -> Bool in
            return obj.name == message.name
        }
        
        if let funcObj = funcObjs.first {
            let pars = message.body as! [AnyObject]
            var dict: [String: AnyObject] = [:]
            for i in 0..<funcObj.parmers.count {
                let key = funcObj.parmers[i]
                if pars.count > i {
                    dict[key] = pars[i]
                }
            }
            
            funcObj.action?(dict)
        }
    }
}

class JKWkWebViewHandler: NSObject {
    fileprivate var name:String!
    fileprivate var parmers:[String]!
    fileprivate var action:(([String:AnyObject]) -> Void)?
}
