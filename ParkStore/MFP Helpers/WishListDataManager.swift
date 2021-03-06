/**
* Copyright 2015 IBM Corp.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import UIKit

class WishListDataManager: NSObject {
    
    var dataStore:CDTStore!
    var appDelegate:AppDelegate!
    let cloudantProxyPath:String = "datastore"
    let remoteStoreName:String = "wishlist9"
    
    class var sharedInstance : WishListDataManager{
        
        struct Singleton {
            static let instance = WishListDataManager()
        }
        return Singleton.instance
    }
    
    func setUpDB(callback:(Bool, [Item]!)->()){
        var manager:IMFDataManager = IMFDataManager.initializeWithUrl(NSUserDefaults.standardUserDefaults().objectForKey("DataProxyCustomServerURL") as! String)
        
        manager.remoteStore(self.remoteStoreName, completionHandler: { (createdStore:CDTStore!, err:NSError!) -> Void in
            if nil != err{
                //error
                println("Error in creating remote store :  \(err.debugDescription)")
                var error:UIAlertView = UIAlertView(title: "Wishlist", message: "There was an error while retrieving the wish list", delegate: nil, cancelButtonTitle: "OK")
                error.show()
            }else{
                self.dataStore = createdStore
                self.dataStore.mapper.setDataType("Item", forClassName: NSStringFromClass(Item.classForCoder()))
                
                println("Successfully created store : \(self.dataStore?.name)")
                
                manager.setCurrentUserPermissions(DB_ACCESS_GROUP_ADMINS, forStoreName: self.remoteStoreName) { (success:Bool, error:NSError!) -> Void in
                    if nil != error {
                        // Handle error
                    } else {
                        self.getWishListItems(callback)
                    }
                }
            }
        })
        
    }
    func getWishListItems(callback:(Bool, [Item]!)->()) {
        
        if self.dataStore == nil {
            self.setUpDB(callback)
        }else{
            let query: CDTQuery = CDTCloudantQuery(dataType: "Item")
            
            self.dataStore.performQuery(query, completionHandler: { (results, error) -> Void in
                if nil != error {
                    // Handle error
                    println("could not retrieve all the data from remote store \(error.debugDescription)")
                } else {
                    callback(true, (results as! [Item]))
                    
                    println("got all records")
                }
            })
        }
    }
    
    func saveItemToWishList(item: Item, callback:()->()){
        
        self.dataStore?.save(item, completionHandler: { (object, err) -> Void in
            if nil != err{
                println("could not save object to cloudant store \(err.debugDescription)")
                var saveFailure:UIAlertView = UIAlertView(title: "ParkStore", message: "Could not save object to cloudant store", delegate: nil, cancelButtonTitle: "OK")
                saveFailure.show()
            }else{
                println("successfully saved object to cloudant store")
                callback()
            }
        })
    }
}
