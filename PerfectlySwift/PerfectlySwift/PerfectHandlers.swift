//
//  PerfectHandlers.swift
//  PerfectlySwift
//
//  Created by Siavash Abbasalipour on 6/09/2016.
//  Copyright © 2016 MobileDen. All rights reserved.
//

import Foundation
import PerfectLib
import PostgreSQL

let dbHost = "localhost"
let dbName = "perfectlySwift"
let dbUsername = "siavashabbasalipour"
let dbPassword = ""

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
    
}

func createPostgreSQLAndConnect() -> PGConnection {
    // open postgre db
    let postgre = PostgreSQL.PGConnection()
    // connect to db
    postgre.connectdb("host='\(dbHost)' dbname='\(dbName)' user='\(dbUsername)' password='\(dbPassword)'")
    return postgre
}

class GetPostHandler: RequestHandler {
    func handleRequest(request: WebRequest, response: WebResponse) {

        let postgre = createPostgreSQLAndConnect()
        
        defer {
            postgre.close()
        }
        
        guard postgre.status() != .Bad else {
            response.setStatus(500, message: "Internal Server Error - failed to connect to db")
            return
        }
        // execute query
        let queryResult = postgre.exec("SELECT content FROM perfect ORDER BY RANDOM() LIMIT 1")
        guard queryResult.status() == .CommandOK || queryResult.status() == .TuplesOK else {
            response.setStatus(500, message: "Internal Server Error - db query error")
            return
        }
        guard case let numberOfFields = queryResult.numFields() where numberOfFields != 0 else {
            response.setStatus(500, message: "Internal Server Error - db returned nothing")
            return
        }
        guard case let numberOfRows = queryResult.numTuples() where numberOfRows != 0 else {
            response.setStatus(204, message: "Internal Server Error - query returned empty result")
            return
        }
        let fieldName = queryResult.fieldName(0)
        let jsonEncoder = JSONEncoder()
        do {
            let responseString = try jsonEncoder.encode([fieldName!:queryResult.getFieldString(0, fieldIndex: 0)])
            // write the JSON to the response body
            response.appendBodyString(responseString)
            response.addHeader("Content-Type", value: "application/json")
            response.setStatus(200, message: "OK")
        } catch {
            print("jsonencoder error!")
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
            
            let postgre = createPostgreSQLAndConnect()
            
            defer {
                postgre.close()
            }
            
            postgre.exec("INSERT INTO perfect (content) VALUES ('\(content!)')")
            
            response.setStatus(201, message: "Created")
            
        } catch let error {
            print(error)
            response.setStatus(400, message: "Bad Request")
        }
        // complete the requesst
        response.requestCompletedCallback()
    }
}