//
//  LoginManager.swift
//  Iris
//
//  Created by Ivailo Kanev on 11/04/21.
//

import Foundation
public enum  LoginManager {
    
}
public extension LoginManager {
    static func isExists(for path: String) -> Bool {
        return item(for: path) != nil
    }
    @discardableResult
    static func add(for path: String) -> Bool {
        guard !isExists(for: path) else {
            return true
        }
        guard let loginItemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() else {
            return false
        }
        let url = URL(fileURLWithPath: path)
        return LSSharedFileListInsertItemURL(loginItemList, kLSSharedFileListItemBeforeFirst.takeRetainedValue(), nil, nil, url as CFURL, nil, nil) != nil
    }
    @discardableResult
    static func remove(for path: String) -> Bool {
        guard let loginItem = item(for: path) else {
            return false
        }
        guard let loginItemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() else {
            return false
        }
        return LSSharedFileListItemRemove(loginItemList, loginItem) == noErr
    }
    static func item(for path: String) -> LSSharedFileListItem? {
        guard let itemList = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems.takeRetainedValue(), nil)?.takeRetainedValue() else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let loginItems = LSSharedFileListCopySnapshot(itemList, nil).takeRetainedValue() as? [LSSharedFileListItem] else {
            return nil
        }
        return loginItems.first(where: {(LSSharedFileListItemCopyResolvedURL($0, 0, nil).takeRetainedValue() as URL).absoluteString == url.absoluteString})
    }
}
