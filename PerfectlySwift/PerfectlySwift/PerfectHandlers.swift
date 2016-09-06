//
//  PerfectHandlers.swift
//  PerfectlySwift
//
//  Created by Siavash Abbasalipour on 6/09/2016.
//  Copyright © 2016 MobileDen. All rights reserved.
//

import Foundation
import PerfectLib

let DB_PATH = PerfectServer.staticPerfectServer.homeDir() + serverSQLiteDBs + "PWSDB"

public func PerfectServerModuleInit() {
    
    Routing.Handler.registerGlobally()
    
    // register a route for getting a post
    Routing.Routes["GET", "/posts"] = { _ in
        return GetPostHandler()
    }
    
    // register a route for creating a post 
    Routing.Routes["POST", "/posts"] = { _ in
        return PostHandler()
    }
    
    // initialise a SQLite db
    do {
        let sqlite = try SQLite(DB_PATH)
        try sqlite.execute("CREATE TABLE IF NOT EXISTS pws (id INTEGER PRIMARY KEY, content STRING)")
    } catch let error {
        print(error)
    }
}

class GetPostHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        do {
            let sqlite = try SQLite(DB_PATH)
            defer {
                sqlite.close()
            }
            // query db
            try sqlite.forEachRow("SELECT content FROM pws ORDER BY RANDOM() LIMIT 1", handleRow: { (statement, i) in
                do {
                    let content = statement.columnText(0)
                    // encode the random content into JSON
                    let jsonEncoder = JSONEncoder()
                    let respString = try jsonEncoder.encode(["content": content])
                    
                    // write the JSON to the response body
                    response.appendBodyString(respString)
                    response.addHeader("Content-Type", value: "application/json")
                    response.setStatus(200, message: "OK")
                    
                } catch let error {
                    response.setStatus(400, message: "Bad Request")
                    print(error)
                }
            })
        } catch let error {
            response.setStatus(400, message: "Bad Request")
            print(error)
        }
        
        response.requestCompletedCallback()
    }
}

class PostHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {
        // get the request body
        let reqData = request.postBodyString
        // Create JSON decoder
        let jsonDecoder = JSONDecoder()
        
        do {
            // decode the requestData
            let json = try jsonDecoder.decode(reqData) as! JSONDictionaryType
            print("Received request JSON: \(json.dictionary)")
            
            let content = json.dictionary["content"] as? String
            
            guard content != nil else {
                // bad request
                response.setStatus(400, message: "Bad Request")
                response.requestCompletedCallback()
                return
            }
            
            // put the content in our Db
            let sqlite = try SQLite(DB_PATH)
            
            // ensure to close the db connection when we are finish
            defer {
                sqlite.close()
            }
            // put the content in db
            try sqlite.execute("INSERT INTO pws (content) VALUES (?)", doBindings: { (statement) in
              try statement.bind(1, content!)
            })
            
            response.setStatus(201, message: "Created")
            
        } catch let error {
            print(error)
            response.setStatus(400, message: "Bad Request")
        }
        // complete the requesst
        response.requestCompletedCallback()
    }
}