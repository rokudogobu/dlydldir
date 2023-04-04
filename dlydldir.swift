
//
//  Copyright (c) 2019-2023 rokudogobu
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

extension Date {static var now:Date {return Date()}}

extension FileManager { 
  
  func contentsOfDirectory(at url:URL) -> [URL] {
    guard url.hasDirectoryPath else {
      return []
    }
    return (try? self.contentsOfDirectory(at:url, includingPropertiesForKeys:nil)) ?? []
  }

}

extension FileHandle {
  
  func print(_ str:String) {
    try? str.utf8CString.withUnsafeBufferPointer {(buf) in 
      try FileHandle.standardError.write(contentsOf:Data(buffer:buf))
    }
  }
  
  func println(_ str:String) {
    self.print(str + "\n")
  }
  
}

extension ISO8601DateFormatter {

  convenience init(withFormatOptions opts:ISO8601DateFormatter.Options, timeZone tz:TimeZone?) {
    self.init()
    self.formatOptions = opts
    self.timeZone      = tz
  }

}

//
//
//

// enum OperationErrorImportance {

//   case ignorable
//   case noteworthy
//   case fatal

// }

enum OperationError:Error {

  case notExists(Item)
  case alreadyOccupied(Item)
  case createFailed(Item, String)
  case trashFailed(Item, String)
  case moveFailed(String, Directory, Directory, String)

  case unknown(String)

  var code:Int32 {
    switch self {
    case .notExists:
      return 1
    case .alreadyOccupied:
      return 2
    case .createFailed:
      return 3
    case .trashFailed:
      return 4
    case .moveFailed:
      return 5
    default:
      return 255
    }
  }

  var localizedDescription:String {
    switch self {
      case .notExists(let item):
        return "'\(item.name)' not exists."
      case .alreadyOccupied(let item):
        return "'\(item.name)' is already occupied"
      case .createFailed(let item, let errdesc):
        return "failed to create '\(item.name)'. (\(errdesc))"
      case .trashFailed(let item, let errdesc):
        return "failed to trash '\(item.name)'. (\(errdesc))"
      case .moveFailed(let name, let from, let to, let errdesc):
        return "failed to move '\(name)' from \(from.name)/ to \(to.name)/. (\(errdesc))"
      default:
        return "unknown error occured."
    }
  }

  // private func err2str(_ err:Error) -> String {
  //   if  NSError.Type {
  //     let e = err as NSError
  //     return "\(e.localizedFailureReason ?? e.localizedDescription) (\(e.code)@\(e.domain))"
  //   } else {
  //     return "\(err.localizedDescription) (\(String(describing:type(of:err)))"
  //   }
  // }

}

extension Error {

  var toString:String {
    let etype = type(of:self)
    switch etype {
      case is NSError.Type:
        let e = self as NSError
        return "\(e.localizedFailureReason ?? e.localizedDescription) (\(e.code)@\(e.domain))"
      case is OperationError.Type:
        return (self as! OperationError).localizedDescription
      default:
        return "\(self.localizedDescription) (\(etype))"
    }
  }

  var toCode:Int32 {
    if type(of:self) is OperationError.Type {
      return (self as! OperationError).code
    } else {
      return 255
    }
  }

  func warn() {
    NSLog("*** warning: " + self.toString)
  }

  func error() {
    NSLog("*** error: " + self.toString)
    exit(self.toCode)
  }

}

//
//
//

struct LocalizedDate {

  private static let formatter = ISO8601DateFormatter(withFormatOptions:[.withFullDate, .withDashSeparatorInDate], 
                                                               timeZone:.current)

  static var today:Self     {return .init(fromDate:.now)}
  static var yesterday:Self {return .init(fromDate:.init(timeIntervalSinceNow:-86400))}

  static let distantPast:LocalizedDate = .init(fromDate:.distantPast)

  let date:Date
  let string:String

  init(fromDate date:Date) {
    self.string = Self.formatter.string(from:date)
    self.date   = Self.formatter.date(from:string)!
  }

  init?(fromString string:String) {
    if let date = Self.formatter.date(from:string) {
      self.init(fromDate:date)
    } else {
      self.init(fromDate:.distantPast)
      return nil
    }
  }

}

extension LocalizedDate:Equatable {
  static func == (lhs:Self, rhs:Self) -> Bool {return lhs.date == rhs.date}
}

extension LocalizedDate:Comparable {
  static func <  (lhs:Self, rhs:Self) -> Bool {return lhs.date <  rhs.date}
}

//
//
//

protocol LocalizedDaily:Comparable {
  var localizedDate:LocalizedDate {get}
}

extension LocalizedDaily {
  static func == (lhs:Self, rhs:Self) -> Bool {return lhs.localizedDate == rhs.localizedDate}
  static func <  (lhs:Self, rhs:Self) -> Bool {return lhs.localizedDate <  rhs.localizedDate}
}

protocol LocalizedToday:LocalizedDaily {

  static var today:Self {get}

  init(withLocalizedDate localizedDate:LocalizedDate)

  var isToday:Bool  {get}
  var isPast:Bool   {get}
  var isFuture:Bool {get}
}

extension LocalizedToday {

  static var today:Self {return .init(withLocalizedDate:.today)}

  var isToday:Bool {
    return self == Self.today
  }

  var isPast:Bool {
    return self < Self.today
  }

  var isFuture:Bool {
    return self > Self.today
  }

}

//
//
//
protocol Item {
  
  var url:URL {get}
  var name:String {get}

  var doesExist:Bool {get}
  var isReachable:Bool {get}
  var isSymbolicLink:Bool {get}
  var isAlias:Bool {get}

  func trash(force:Bool) throws

}

extension Item {

  var name:String {
    return self.url.lastPathComponent
  }

  var doesExist:Bool {
    return self.isReachable
  }

  var isReachable:Bool {
    return (try? self.url.checkResourceIsReachable()) ?? false
  }

  var isDirectory:Bool {
    guard let rsrcVals = try? url.resourceValues(forKeys: [.isDirectoryKey]) else {
      return false
    }
    return rsrcVals.isDirectory ?? false
  }

  var isSymbolicLink:Bool {
    if let rsrcVals = try? url.resourceValues(forKeys: [.isSymbolicLinkKey]) {
      return rsrcVals.isSymbolicLink ?? false
    }
    return false
  }

  private var isAliasFile:Bool {
    if let rsrcVals = try? url.resourceValues(forKeys: [.isAliasFileKey]) {
      return rsrcVals.isAliasFile ?? false
    }
    return false
  }

  var isAlias:Bool {
    return (!self.isSymbolicLink) && self.isAliasFile
  }

  func trash(force:Bool = false) throws {
    do {
      try FileManager.default
                    .trashItem(at:self.url, 
                  resultingItemURL:nil)
    } catch {
      throw OperationError.trashFailed(self, error.toString)
    }
  }

}

//
//
//
protocol Directory:Item {

  var contents:[URL] {get}
  var isEmpty:Bool {get}

  func create() throws

}

extension Directory {

  var doesExist:Bool {
    return self.isDirectory
  }

  var contents:[URL] {
    return FileManager.default
                      .contentsOfDirectory(at:self.url)
                      .filter {url in
                        !(url.isFileURL && url.lastPathComponent == ".DS_Store")
                      }
  }

  var isEmpty:Bool {
    return self.contents.count == 0
  }

  func create() throws {
    do {
      try FileManager.default
                    .createDirectory(at:self.url, 
            withIntermediateDirectories:false, 
                              attributes:nil)
    } catch {
      throw OperationError.createFailed(self, error.toString)
    }
  }

}

protocol SymbolicLink:Item {
  
  var destination:URL {get}

  func create<T:Item>(withDestination dest:T) throws

}

extension SymbolicLink {

  var doesExist:Bool {
    return self.isSymbolicLink
  }

  var destination:URL {
    return self.url.resolvingSymlinksInPath()
  }

  func create<T:Item>(withDestination dest:T) throws {
    do {
      try FileManager.default
                    .createSymbolicLink(at:self.url,
                        withDestinationURL:dest.url)
    } catch {
      throw OperationError.createFailed(self, error.toString)
    }
  }

}

//
//
//
class DownloadsSubItem:Item {

  static let parent:URL = try! FileManager.default.url(for:.downloadsDirectory, 
                                                        in:.userDomainMask, 
                                            appropriateFor:nil, 
                                                    create:false)

  let url:URL

  init(withName name:String) {
    self.url = Self.parent
                   .appendingPathComponent(name, isDirectory:true)
                   .absoluteURL
  }

}

//
//
//
class DownloadsDailySubItem:DownloadsSubItem, LocalizedDaily {

  let localizedDate:LocalizedDate

  required init(withLocalizedDate localizedDate:LocalizedDate) {
    self.localizedDate = localizedDate
    super.init(withName:localizedDate.string)
  }

  convenience init(withDate date:Date) {
    self.init(withLocalizedDate:LocalizedDate(fromDate:date))
  }

  convenience init?(fromString name:String) {
    if let localizedDate = LocalizedDate(fromString:name) {
      self.init(withLocalizedDate:localizedDate)
    } else {
      self.init(withLocalizedDate:.distantPast)
      return nil
    }
  }

}

//
//
//
final class DesignatedDownloadDirectory:DownloadsSubItem, Directory {

  static let today:DesignatedDownloadDirectory = .init(withName:"today")

  private func checkContentShouldIgnored(at url:URL) -> Bool {
    let name = url.lastPathComponent
    let ext  = url.pathExtension
    return (url.isFileURL && name == ".DS_Store") 
           || ext == "download"
           || ext == "crdownload"
  }

  private func moveContent<T:Directory>(at src:URL, to dir:T) throws {

    if self.checkContentShouldIgnored(at:src) {
      return
    }

    let name = src.lastPathComponent
    let dst  = dir.url.appendingPathComponent(name, isDirectory:src.hasDirectoryPath)
    do {
      try FileManager.default.moveItem(at:src, to:dst)
    } catch {
      throw OperationError.moveFailed(name, self, dir, error.toString)
    }
    
  }

  func moveContents<T:Directory>(to dir:T) throws {
    
    try self.contents.forEach {src in 
      try self.moveContent(at:src, to:dir)
    }
    
  }

}

//
//
//
final class DailyArchiveDirectory:DownloadsDailySubItem, LocalizedToday, Directory {
  
  class func list() -> [DailyArchiveDirectory] {
    return FileManager.default
                      .contentsOfDirectory(at:Self.parent)
                      .compactMap {
                        Self(fromString:$0.lastPathComponent)
                      }.filter {
                        $0.doesExist && $0.isPast
                      }.sorted {
                        $0 < $1
                      }
  }

}

final class DailyDownloadSymbolicLink:DownloadsDailySubItem, LocalizedToday, SymbolicLink {
  
  class func list() -> [DailyDownloadSymbolicLink] {
    return FileManager.default
                      .contentsOfDirectory(at:Self.parent)
                      .compactMap {
                        Self(fromString:$0.lastPathComponent)
                      }.filter {
                        $0.doesExist && !$0.isFuture
                      }.sorted {
                        $0 < $1
                      }
  }

}

//
//
//

final class DailyDownloadDirectory {

  let designated:DesignatedDownloadDirectory
  // var usingNSLog = false

  init(withDesignated designated:DesignatedDownloadDirectory = .today) {
    self.designated = designated
  }

  var marks:[DailyDownloadSymbolicLink] {
    return DailyDownloadSymbolicLink.list().filter {
      self.checkDesignatedIsMarked(as:$0)
    }
  }

  func checkDesignatedIsMarked<T:SymbolicLink>(as mark:T) -> Bool {
    return mark.doesExist && mark.destination == self.designated.url
  }

  //
  //
  //
  func create() throws {

    if self.designated.doesExist {
      return
    } else if self.designated.isReachable {
      throw OperationError.alreadyOccupied(self.designated)
    } else {
      try self.designated.create()
    }

  }

  func archive() throws {
    
    guard self.designated.doesExist else {
      throw OperationError.notExists(self.designated)
    }

    guard let mark = self.marks.last else {
      throw OperationError.notExists(DailyDownloadSymbolicLink.today)
    }

    if mark.isToday {
      return
    } else {
      try mark.trash()
    }

    let dir = DailyArchiveDirectory(withLocalizedDate:mark.localizedDate)
    try dir.create()

    try self.designated.moveContents(to:dir)  

  }

  private func trashMarks(except:[DailyDownloadSymbolicLink] = []) throws {

    try self.marks.filter {
      !except.contains($0)
    }.forEach {
      try $0.trash()
    }

  }

  func mark(as localizedDate:LocalizedDate = .today) throws {

    guard self.designated.doesExist else {
      throw OperationError.notExists(self.designated)
    }

    let mark = DailyDownloadSymbolicLink(withLocalizedDate:localizedDate)
    if self.checkDesignatedIsMarked(as:mark) {
      return
    } else {
      try mark.create(withDestination:self.designated)
    }

    try self.trashMarks(except:[mark])

  }

  private func trashEmptyArchiveDirectories(except:[DailyArchiveDirectory] = []) throws {
    
    try DailyArchiveDirectory.list().filter {
      !except.contains($0)
    }.filter {dir in
      dir.isDirectory && dir.isEmpty
    }.forEach { dir in
      try dir.trash()  
    }

  }

  func clean() throws {
    try self.trashMarks(except:[.today])
    try self.trashEmptyArchiveDirectories()
  }

  //
  //
  //
  // private func println(_ str:String) {
  //   if usingNSLog {
  //     NSLog("%s", str)
  //   } else {
  //     FileHandle.standardError
  //               .println(str)
  //   }
  // }

  // private func warn(withMessage msg:String) {
  //   self.println("*** warning: " + msg)
  // }

  // private func error(withMessage msg:String = "encountered unknown error.", 
  //                               code:Int32 = OperationError.unknown.code) {
  //   self.println("*** error: " + msg)
  //   exit(code)
  // }

  // private func err2msg(_ err:Error) -> String {
  //   switch type(of:err) {
  //     case is NSError.Type:
  //       let e = err as NSError
  //       return "\(e.localizedFailureReason ?? e.localizedDescription) (\(e.code)@\(e.domain))"
  //     case is OperationError.Type:
  //       return (err as! OperationError).localizedDescription
  //     default:
  //       return "\(err.localizedDescription) (\(type(of:err)))"
  //   }
  // }

  //
  //
  //
  func main() throws {
    
    try create()
    do {
      try archive()
    } catch OperationError.notExists {
      // if mark does not exist, do nothing
    }
    try mark()
    try clean()

    // do {
      
    //   try create()
    //   do {
    //     try archive()
    //   } catch OperationError.notExists {
    //     // if mark does not exist, do nothing
    //   }
    //   try mark()
    //   try clean()

    // } catch let err {

    //   let msg = self.err2msg(err)

    //   var exitCode:Int32 = -1
    //   // var errImportance:OperationErrorImportance = .ignorable
    //   switch type(of:err) {
    //     case is OperationError.Type:
    //       // switch err as! OperationError {
    //       //   case .moveFailed:
    //       //     errImportance = .noteworthy
    //       //   default:
    //       //     errImportance = .fatal
    //       // }
    //       exitCode = (err as! OperationError).code
    //     default:
    //       // errImportance = .noteworthy
    //       exitCode = OperationError.unknown.code
    //   }

    //   // switch errImportance {
    //   //   case .ignorable:
    //   //     break
    //   //   case .noteworthy:
    //   //     self.warn(withMessage:msg)
    //   //   case .fatal:
    //   //     self.error(withMessage:msg, code:exitCode)
    //   // }

    //   self.error(withMessage:msg, code:exitCode)
      
    // }

  }
}



//
// main
//

let dlydldir = DailyDownloadDirectory()

var i = 1
while i < CommandLine.arguments.count {
  switch CommandLine.arguments[i].lowercased() {
    // case "--nslog":
    //   dlydldir.usingNSLog = true
    default:
      break
  }
  i += 1
}

// dlydldir.main()

do {
  
  try dlydldir.create()
  do {
    try dlydldir.archive()
  } catch OperationError.notExists {
    // if mark does not exist, do nothing
  }
  try dlydldir.mark()
  try dlydldir.clean()

} catch {

  NSLog("*** error: " + error.toString)

}


