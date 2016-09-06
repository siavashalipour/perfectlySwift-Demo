//
//  ViewController.swift
//  PerfectlySwiftClient
//
//  Created by Siavash Abbasalipour on 6/09/2016.
//  Copyright © 2016 MobileDen. All rights reserved.
//

import UIKit
import PerfectLib

class MainViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    
    private let WS_HOST = "localhost"
    private let WS_PORT = "8181"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func postEndPoint() -> String {
        return "http://\(WS_HOST):\(WS_PORT)/posts"
    }
    
    @IBAction func postTap(sender: UIButton) {
        do {
            print("Creating request for content: \(textField.text)")
            let request = NSMutableURLRequest(URL: NSURL(string: postEndPoint())!)
            request.HTTPMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // make json packet
            let jsonEndocer = JSONEncoder()
            let json = try jsonEndocer.encode(["content":textField.text])
            
            // set request body
            request.HTTPBody = json.dataUsingEncoding(NSASCIIStringEncoding)
            
            // send the request
            print("sending request \(request)")
            let session = NSURLSession.sharedSession()
            session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                
                if error != nil {
                    print("Error Session Task: \(error)")
                }
                print(response)
            }).resume()
            textField.text = ""
        } catch {
            print("Error Posting Content")
        }
    }

    @IBAction func newPostTap(sender: UIButton) {
        
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(NSURL(string: postEndPoint())!) { [weak self] (data, response, error) in
            guard let safeData = data else {
                print("NO DATA")
                return
            }
            do {
                // decode thr json
                let string = String(data: safeData, encoding: NSASCIIStringEncoding)!
                let jsonDecoder = JSONDecoder()
                let json = try jsonDecoder.decode(string) as! JSONDictionaryType
                let content = json.dictionary["content"] as! String
                
                dispatch_async(dispatch_get_main_queue(), { 
                    self?.textView.text = content
                })
            }  catch {
                print("error getting posts")
            }
        }.resume()
    }
}

