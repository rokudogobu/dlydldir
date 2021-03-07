
//
//  Copyright (c) 2019-2021 rokudogobu
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

extension Date {
    static let now:Date  = .init()
}

extension URL {
    static let home      = FileManager.default.homeDirectoryForCurrentUser
    static let downloads = home.appendingPathComponent("Downloads", isDirectory:true)
    static let today     = downloads.appendingPathComponent(ISO8601DateFormatter.localizedTodayString(), isDirectory:true)
}

//
//
//

extension FileManager {
    
    class func contentsOfDirectory(at url:URL) -> [URL] {
        if url.hasDirectoryPath {
            do {
                return try self.default.contentsOfDirectory(at:url, includingPropertiesForKeys:nil)
            }
            catch {
                return []
            }
        }
        return []
    }
    
    class func directoryExists(at:URL) -> Bool {
        var isdir:ObjCBool = false
        return FileManager.default.fileExists(atPath:at.path, isDirectory:&isdir) && isdir.boolValue
    }
    
    class func destinationOfSymbolicLink(at url:URL) -> URL? {
        do {
            return URL(fileURLWithPath:try FileManager.default.destinationOfSymbolicLink(atPath:url.path))
        } catch {
            return nil
        }
    }
    
}

extension ISO8601DateFormatter {
    
    class func localizedDateString(from date:Date) -> String {
        return self.string(from:date, timeZone:.current, formatOptions:[.withFullDate])
    }
    
    class func localizedTodayString() -> String {
        return self.localizedDateString(from:.init())
    }

    class func localizedTomorrowString() -> String {
        return self.localizedDateString(from:.init(timeIntervalSinceNow:86400))
    }
    
}

extension URL {
    
    func appendingPathComponents(_ components:[String], isDirectory:Bool) -> URL {
        var url = self
        if components.count > 0 {
            var ancestors = components
            let lastPathComponent = ancestors.removeLast()
            url = self.appendingPathComponents(ancestors, isDirectory:true)
            url = url.appendingPathComponent(lastPathComponent, isDirectory:isDirectory)
        }
        return url
    }
    
}

//
//
//

class DailyDownloadDirectory {
    
    class func list() -> [DailyDownloadDirectory] {
        var dirs:[DailyDownloadDirectory] = []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate
        formatter.timeZone      = .current
        
        for item in FileManager.contentsOfDirectory(at:URL.downloads) {
            if let date = formatter.date(from:item.lastPathComponent) {
                if date < Date.now {
                    dirs.append(DailyDownloadDirectory(forDate:date))
                }
            }
        }
        
        return dirs
    }
    
    class func clean() {
        for dir in self.list() {
            if dir.isEmpty
              && dir.url != URL.today
              && dir.date < Date.now {
                dir.trash()
            }
        }
    }
    
    let name:String
    let url:URL
    let date:Date
    
    var path:String {
        return self.url.path
    }
    
    var doesExist:Bool {
        return FileManager.directoryExists(at:self.url)
    }
    
    var isEmpty:Bool {
        return FileManager.contentsOfDirectory(at:self.url)
                          .filter({!($0.isFileURL && $0.lastPathComponent == ".DS_Store")})
                          .count == 0
    }
    
    init(forDate date:Date) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate
        formatter.timeZone      = .current
        
        self.name = ISO8601DateFormatter.localizedDateString(from:date)
        self.date = formatter.date(from:self.name)!
        self.url  = URL.downloads.appendingPathComponent(self.name, isDirectory:true)
    }
    
    func create() {
        if !FileManager.default.fileExists(atPath:self.path) {
            do {
                try FileManager.default.createDirectory(at:self.url, withIntermediateDirectories:false, attributes:nil)
            } catch {
                // error
            }
        } else if !self.doesExist {
            // error
        }
    }
    
    func createSymbolicLink(_ name:String) {
        let link = URL.downloads.appendingPathComponent(name, isDirectory:true)
        
        if FileManager.default.fileExists(atPath:link.path) {
            if let dest = FileManager.destinationOfSymbolicLink(at:link) {
                if self.url != dest {
                    do {
                        try FileManager.default.trashItem(at:link, resultingItemURL:nil)
                    } catch {
                        // error
                    }
                }
            } else {
                // error
            }
        }
        
        do {
            try FileManager.default.createSymbolicLink(at:URL.downloads.appendingPathComponent(name), withDestinationURL:self.url)
        } catch {
            // error
        }
    }
    
    func set() {
        let args = [
            "write",
            "-app",
            "Safari",
            "DownloadsPath",
            "-string",
            self.url.path
        ]
        
        if self.doesExist {
            do {
                try Process.run(URL(fileURLWithPath:"/usr/bin/defaults"), arguments:args, terminationHandler:nil)
            } catch {
                // error
            }
        }
    }
    
    func trash(force:Bool = false) {
        if self.doesExist && (force || self.isEmpty) {
            do {
                try FileManager.default.trashItem(at:self.url, resultingItemURL:nil)
            } catch {
                // error
            }
        }
    }

}

//
//
//

func main() {
    
    let today = DailyDownloadDirectory(forDate:.now)
    today.create()
    today.createSymbolicLink("today")
    today.set()

    DailyDownloadDirectory.clean()
    
}

//
//
//

main()
