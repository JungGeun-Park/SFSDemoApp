func performAllFileIOOperations() {
    // This function showcases a wide variety of file I/O operations in Swift.
    // It intentionally mixes multiple Foundation APIs to demonstrate different usage patterns.

    let fileURL = URL(fileURLWithPath: "test.txt")  // A simple file URL based on a relative path.
    let filePath = "test2.txt"                      // Plain file system path as String (for legacy APIs).

    // ==================== Data ====================
    do {
        // Data(contentsOf:) synchronously reads the entire file into memory.
        // Use this only for reasonably small files since it loads everything at once.
        let data = try Data(contentsOf: fileURL)
        print("Data length: \(data.count)")

        // write(to:) synchronously writes the entire Data back to disk.
        // Here it's just demonstrating round‑trip I/O.
        try data.write(to: fileURL)
    } catch {
        // Basic error handling: in production, you might want to handle specific error types.
        print("Data error: \(error)")
    }

    // ==================== FileHandle ====================
    // FileHandle is good for random access, partial reads, appending, and truncation.

    if !FileManager.default.fileExists(atPath: filePath) {
        // Create an initial file if needed so the subsequent FileHandle usage succeeds.
        FileManager.default.createFile(atPath: filePath,
                                       contents: "Initial".data(using: .utf8),
                                       attributes: nil)
    }

    do {
        // forUpdating opens the file for both reading and writing.
        let handle = try FileHandle(forUpdating: URL(fileURLWithPath: filePath))

        // defer is critical to ensure the file descriptor is closed even if an error occurs.
        defer { handle.closeFile() }

        // --- Read entire contents from current offset to EOF ---
        do {
            // readToEnd() consumes from the current cursor position.
            let readData = try handle.readToEnd() ?? Data()
            print("Read to end: \(String(data: readData, encoding: .utf8) ?? "")")
        } catch {
            print("FileHandle readToEnd error: \(error)")
        }

        // --- Read a subset of bytes from the beginning of the file ---
        do {
            // Reset the file cursor to the beginning.
            try handle.seek(toOffset: 0)

            // read(upToCount:) is useful when you only want a chunk of data.
            let partData = try handle.read(upToCount: 5) ?? Data()
            print("Partial read: \(String(data: partData, encoding: .utf8) ?? "")")
        } catch {
            print("FileHandle seek/read error: \(error)")
        }

        // --- Write data at a given offset (overwrite from the start) ---
        do {
            try handle.seek(toOffset: 0)
            // Force unwrap is okay in this demo; avoid it in production code.
            try handle.write(contentsOf: "Start-".data(using: .utf8)!)
        } catch {
            print("FileHandle write error: \(error)")
        }

        // --- Truncate file to a fixed length ---
        do {
            // This will cut any bytes after the 7th byte.
            try handle.truncate(atOffset: 7)
        } catch {
            print("FileHandle truncate error: \(error)")
        }

    } catch {
        print("FileHandle error: \(error)")
    }

    // ==================== InputStream ====================
    // InputStream is a classic stream-based API, good for incremental reads.

    if let inputStream = InputStream(url: fileURL) {
        inputStream.open()
        defer { inputStream.close() }

        // Simple fixed-size buffer for demonstration.
        var buffer = [UInt8](repeating: 0, count: 8)

        // read(_:maxLength:) returns the number of bytes actually read, or -1 on error.
        let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
        if bytesRead > 0 {
            let snippet = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""
            print("InputStream read \(bytesRead) bytes: \(snippet)")
        }
    }

    // ==================== OutputStream ====================
    // OutputStream is the write counterpart of InputStream.

    if let outputStream = OutputStream(url: fileURL, append: false) {
        outputStream.open()
        defer { outputStream.close() }

        // ASCII values for the string "World".
        let bytes: [UInt8] = [87, 111, 114, 108, 100]
        let written = outputStream.write(bytes, maxLength: bytes.count)

        // Written count should match bytes.count if the write was fully successful.
        print("OutputStream wrote \(written) bytes")
    }

    // ==================== NSData ====================
    // NSData is the Objective‑C equivalent of Data (immutable).

    do {
        // NSData(contentsOfFile:) is a throwing initializer here (per this code),
        // though Foundation’s real API often returns an optional instead.
        if let nsData = try NSData(contentsOfFile: filePath) {
            print("NSData length: \(nsData.length)")

            // Write using Objective‑C style path‑based API.
            nsData.write(toFile: "NSDataWritten.txt", atomically: true)

            // The URL‑based method can throw, hence the try keyword.
            try nsData.write(to: fileURL as URL, options: .atomic)
        } else {
            print("NSData(contentsOfFile:) returned nil")
        }
    } catch {
        print("NSData error: \(error)")
    }

    // ==================== NSMutableData ====================
    // NSMutableData offers in-place mutation and append operations.

    if let mutableData = NSMutableData(capacity: 50) {
        // Append some initial text.
        mutableData.append("Mutable".data(using: .utf8)!)

        // Save intermediate data to a file.
        mutableData.write(toFile: "NSMutableData.txt", atomically: true)

        // Append more text later.
        mutableData.append(" Append".data(using: .utf8)!)
        print("NSMutableData length: \(mutableData.length)")
    }

    // ==================== FileManager ====================
    // FileManager is the main API for higher-level file system operations.

    let fm = FileManager.default
    let created = fm.createFile(atPath: "FMFile.txt",
                                contents: "FM Test".data(using: .utf8),
                                attributes: nil)
    print("FileManager created: \(created)")

    // ==================== 다양한 조합 ====================
    // Below: combined usage of Data, FileHandle, and streams for more complex flows.

    do {
        // Load current contents.
        var tempData = try Data(contentsOf: fileURL)

        // Append extra text into a temporary buffer.
        tempData.append(" Extra".data(using: .utf8)!)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { handle.closeFile() }

            // Move cursor to end to append.
            try handle.seekToEnd()

            // Write the entire accumulated data.
            try handle.write(contentsOf: tempData)
        }
    } catch {
        print("Combination error: \(error)")
    }

    // Another combination using NSMutableData and OutputStream.
    if let mData = NSMutableData(capacity: 100) {
        mData.append("StreamTest".data(using: .utf8)!)

        // Open an OutputStream in append mode.
        if let oStream = OutputStream(url: fileURL, append: true) {
            oStream.open()
            defer { oStream.close() }

            // Bind NSMutableData's raw bytes to UInt8 pointer for stream writing.
            _ = oStream.write(mData.bytes.bindMemory(to: UInt8.self, capacity: mData.length),
                              maxLength: mData.length)
        }
    }

    // Copy from InputStream to another file using FileHandle.
    if let input = InputStream(url: fileURL) {
        input.open()
        defer { input.close() }

        var buf = [UInt8](repeating: 0, count: 16)
        let read = input.read(&buf, maxLength: buf.count)

        if read > 0 {
            let outFile = "InputStreamToFile.txt"

            // Ensure target file exists.
            if !FileManager.default.fileExists(atPath: outFile) {
                FileManager.default.createFile(atPath: outFile,
                                               contents: nil,
                                               attributes: nil)
            }

            do {
                // Use FileHandle to append the bytes read from the stream.
                let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: outFile))
                defer { handle.closeFile() }

                try handle.seekToEnd()
                try handle.write(contentsOf: Data(buf[0..<read]))
            } catch {
                print("InputStream to file error: \(error)")
            }
        }
    }
}


func performAllFileIOOperations_Extended() async {
    // Extended version: demonstrates I/O in the user’s Documents directory,
    // more FileManager utilities, async FileHandle APIs, and Obj‑C bridge types.

    let fm = FileManager.default

    // ==== Prepare common base directory (Documents/IOExamples) ====
    let docsURL: URL
    do {
        // This locates the app’s Documents directory in the user domain.
        docsURL = try fm.url(for: .documentDirectory,
                             in: .userDomainMask,
                             appropriateFor: nil,
                             create: true)
    } catch {
        // If Documents directory cannot be resolved, bail out early.
        print("Documents URL error: \(error)")
        return
    }

    // Base directory for all sample files used in this function.
    let baseDirURL = docsURL.appendingPathComponent("IOExamples", isDirectory: true)

    // Individual file URLs used throughout this extended demonstration.
    let fileURL = baseDirURL.appendingPathComponent("test.txt")
    let file2URL = baseDirURL.appendingPathComponent("test2.txt")
    let nsDataFileURL = baseDirURL.appendingPathComponent("NSDataWritten.txt")
    let mutableDataFileURL = baseDirURL.appendingPathComponent("NSMutableData.txt")
    let fmFileURL = baseDirURL.appendingPathComponent("FMFile.txt")
    let inputStreamToFileURL = baseDirURL.appendingPathComponent("InputStreamToFile.txt")
    let stringFileURL = baseDirURL.appendingPathComponent("StringExample.txt")
    let asyncFileURL = baseDirURL.appendingPathComponent("AsyncFileHandle.txt")
    let wrapperDirURL = baseDirURL.appendingPathComponent("WrapperDir", isDirectory: true)
    let wrapperOutDirURL = baseDirURL.appendingPathComponent("WrapperOut", isDirectory: true)

    // Ensure the base directory exists (creates intermediate directories as needed).
    do {
        try fm.createDirectory(at: baseDirURL,
                               withIntermediateDirectories: true,
                               attributes: nil)
    } catch {
        print("Base dir create error: \(error)")
        return
    }

    // ==================== Data ====================
    do {
        // Write a simple string as Data to the file.
        try "Data Start".data(using: .utf8)!.write(to: fileURL)

        // Synchronously read it back using Data(contentsOf:).
        let data = try Data(contentsOf: fileURL)
        print("Data length: \(data.count)")

        // Overwrite with the same data, just to demonstrate Data.write(to:).
        try data.write(to: fileURL)
    } catch {
        print("Data error: \(error)")
    }

    // ==================== FileHandle (동기) ====================
    if !fm.fileExists(atPath: file2URL.path) {
        // Create an initial file for the FileHandle demonstration.
        fm.createFile(atPath: file2URL.path,
                      contents: "Initial".data(using: .utf8),
                      attributes: nil)
    }

    do {
        // forUpdating: open file for reading and writing.
        let handle = try FileHandle(forUpdating: file2URL)
        defer { try? handle.close() }

        // ---- Read entire file contents to the end ----
        do {
            let readData = try handle.readToEnd() ?? Data()
            print("Read to end: \(String(data: readData, encoding: .utf8) ?? "")")
        } catch {
            print("FileHandle readToEnd error: \(error)")
        }

        // ---- Partial read from the beginning ----
        do {
            try handle.seek(toOffset: 0)
            let partData = try handle.read(upToCount: 5) ?? Data()
            print("Partial read: \(String(data: partData, encoding: .utf8) ?? "")")
        } catch {
            print("FileHandle seek/read error: \(error)")
        }

        // ---- Overwrite some bytes at the start of the file ----
        do {
            try handle.seek(toOffset: 0)
            try handle.write(contentsOf: "Start-".data(using: .utf8)!)
        } catch {
            print("FileHandle write error: \(error)")
        }

        // ---- Truncate file to 7 bytes ----
        do {
            try handle.truncate(atOffset: 7)
        } catch {
            print("FileHandle truncate error: \(error)")
        }

    } catch {
        print("FileHandle error: \(error)")
    }

    // ==================== InputStream ====================
    if let inputStream = InputStream(url: fileURL) {
        inputStream.open()
        defer { inputStream.close() }

        var buffer = [UInt8](repeating: 0, count: 8)
        let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)

        if bytesRead > 0 {
            let snippet = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? ""
            print("InputStream read \(bytesRead) bytes: \(snippet)")
        }
    }

    // ==================== OutputStream ====================
    if let outputStream = OutputStream(url: fileURL, append: false) {
        outputStream.open()
        defer { outputStream.close() }

        let bytes: [UInt8] = [87, 111, 114, 108, 100] // "World"
        let written = outputStream.write(bytes, maxLength: bytes.count)
        print("OutputStream wrote \(written) bytes")
    }

    // ==================== NSData ====================
    // Demonstrates bridging back and forth between Swift and Objective‑C Data types.

    do {
        // In real Foundation, NSData(contentsOfFile:) usually returns an optional without throwing.
        if let nsData = NSData(contentsOfFile: file2URL.path) {
            print("NSData length: \(nsData.length)")

            // Persist NSData to disk with Obj‑C style API.
            nsData.write(toFile: nsDataFileURL.path, atomically: true)

            // URL‑based write supports options and can throw errors.
            try nsData.write(to: fileURL, options: .atomic)
        } else {
            print("NSData(contentsOfFile:) returned nil")
        }
    } catch {
        print("NSData error: \(error)")
    }

    // ==================== NSMutableData ====================
    if let mutableData = NSMutableData(capacity: 50) {
        mutableData.append("Mutable".data(using: .utf8)!)
        mutableData.write(toFile: mutableDataFileURL.path, atomically: true)

        // Append another string in-place.
        mutableData.append(" Append".data(using: .utf8)!)
        print("NSMutableData length: \(mutableData.length)")
    }

    // ==================== FileManager (기본) ====================
    let created = fm.createFile(atPath: fmFileURL.path,
                                contents: "FM Test".data(using: .utf8),
                                attributes: nil)
    print("FileManager created: \(created)")

    // ==================== 다양한 조합 (Data + FileHandle + Stream) ====================
    do {
        // Start with contents of fileURL.
        var tempData = try Data(contentsOf: fileURL)

        // Add some extra text to be appended later.
        tempData.append(" Extra".data(using: .utf8)!)

        if fm.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }

            // Append to the end of the file.
            try handle.seekToEnd()
            try handle.write(contentsOf: tempData)
        }
    } catch {
        print("Combination error: \(error)")
    }

    // Append to file using OutputStream and NSMutableData buffer.
    if let mData = NSMutableData(capacity: 100) {
        mData.append("StreamTest".data(using: .utf8)!)

        if let oStream = OutputStream(url: fileURL, append: true) {
            oStream.open()
            defer { oStream.close() }

            _ = oStream.write(mData.bytes.bindMemory(to: UInt8.self,
                                                     capacity: mData.length),
                              maxLength: mData.length)
        }
    }

    // Copy a chunk from InputStream into another file.
    if let input = InputStream(url: fileURL) {
        input.open()
        defer { input.close() }

        var buf = [UInt8](repeating: 0, count: 16)
        let read = input.read(&buf, maxLength: buf.count)

        if read > 0 {
            if !fm.fileExists(atPath: inputStreamToFileURL.path) {
                fm.createFile(atPath: inputStreamToFileURL.path,
                              contents: nil,
                              attributes: nil)
            }

            do {
                let handle = try FileHandle(forWritingTo: inputStreamToFileURL)
                defer { try? handle.close() }

                try handle.seekToEnd()
                try handle.write(contentsOf: Data(buf[0..<read]))
            } catch {
                print("InputStream to file error: \(error)")
            }
        }
    }

    // ==================== String <-> 파일 ====================
    // Demonstrates Swift’s convenience APIs for text file I/O.

    do {
        let text = "Hello String File I/O\n두 번째 줄"

        // Swift String’s write(to:atomically:encoding:) is very convenient but
        // might not be allowed in some strict environments (e.g., sandbox policies).
        try text.write(to: stringFileURL, atomically: true, encoding: .utf8)

        let readBack = try String(contentsOf: stringFileURL, encoding: .utf8)
        print("String read:\n\(readBack)")
    } catch {
        print("String file error: \(error)")
    }

    // ==================== FileManager 확장 기능들 ====================
    // Create, copy, move, list, inspect, and delete items in a subdirectory.

    do {
        // Create a nested subdirectory.
        let subDirURL = baseDirURL.appendingPathComponent("SubDir", isDirectory: true)
        try fm.createDirectory(at: subDirURL,
                               withIntermediateDirectories: true,
                               attributes: nil)

        // Create a simple file inside the subdirectory.
        let subFileURL = subDirURL.appendingPathComponent("sub.txt")
        fm.createFile(atPath: subFileURL.path,
                      contents: "Sub File".data(using: .utf8),
                      attributes: nil)

        // Prepare URLs for copy and move targets.
        let copyDestURL = subDirURL.appendingPathComponent("sub_copy.txt")
        let moveDestURL = subDirURL.appendingPathComponent("sub_moved.txt")

        // Copy the file.
        try fm.copyItem(at: subFileURL, to: copyDestURL)

        // Move (rename) the copied file.
        try fm.moveItem(at: copyDestURL, to: moveDestURL)

        // List contents of SubDir with selected resource keys.
        let items = try fm.contentsOfDirectory(at: subDirURL,
                                              includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                                              options: [.skipsHiddenFiles])
        print("SubDir items:")
        for url in items {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            let isFile = values.isRegularFile ?? false
            let size = values.fileSize ?? 0
            print("- \(url.lastPathComponent) isFile: \(isFile) size: \(size)")
        }

        // Query file attributes using attributesOfItem.
        let attrs = try fm.attributesOfItem(atPath: subFileURL.path)
        print("Attributes of subFile: \(attrs)")

        // Clean up: remove files and the directory.
        try fm.removeItem(at: moveDestURL)
        try fm.removeItem(at: subFileURL)
        try fm.removeItem(at: subDirURL)
    } catch {
        print("FileManager advanced error: \(error)")
    }

    // ==================== URL 리소스 값 ====================
    // URL resourceValues are handy for metadata like file size or creation date.

    do {
        var values = try fileURL.resourceValues(forKeys: [.isRegularFileKey,
                                                         .creationDateKey,
                                                         .fileSizeKey])

        print("fileURL isRegularFile: \(values.isRegularFile ?? false)")
        print("fileURL creationDate: \(String(describing: values.creationDate))")
        print("fileURL fileSize: \(String(describing: values.fileSize))")

        // Example: preparing to set some resource values (hidden flag).
        var setValues = URLResourceValues()
        setValues.isHidden = false
        // fileURL.setResourceValues(setValues) would apply the changes.
        // (Commented out here to avoid side effects.)
    } catch {
        print("URL resource values error: \(error)")
    }

    // ==================== FileHandle 비동기 (iOS 15+ / macOS 12+) ====================
    // Modern async FileHandle APIs allow non‑blocking read/write operations.[web:1][web:14]

    if #available(iOS 15.0, macOS 12.0, *) {
        do {
            // Seed the async file with some initial data.
            try "Async Start".data(using: .utf8)!.write(to: asyncFileURL)

            // Open FileHandle for asynchronous updating.
            let asyncHandle = try FileHandle(forUpdating: asyncFileURL)
            defer { try? asyncHandle.close() }

            // Asynchronously move to end and append more text.
            try await asyncHandle.seekToEnd()
            try await asyncHandle.write(contentsOf: " + More".data(using: .utf8)!)

            // Seek back to the beginning and read everything asynchronously.
            try await asyncHandle.seek(toOffset: 0)
            if let data = try await asyncHandle.readToEnd() {
                print("Async FileHandle read: \(String(data: data, encoding: .utf8) ?? "")")
            }
        } catch {
            print("Async FileHandle error: \(error)")
        }
    }

    // ==================== FileWrapper ====================
    // FileWrapper is useful for representing and serializing complex file hierarchies.[web:18][web:15]

    do {
        // Clean up any previous wrapper directories if they exist.
        try? fm.removeItem(at: wrapperDirURL)
        try? fm.removeItem(at: wrapperOutDirURL)

        // Create source directory for FileWrapper.
        try fm.createDirectory(at: wrapperDirURL,
                               withIntermediateDirectories: true,
                               attributes: nil)

        // Place an inner text file in the directory to wrap.
        let innerFileURL = wrapperDirURL.appendingPathComponent("inner.txt")
        try "Inner File".data(using: .utf8)!.write(to: innerFileURL)

        // Create a directory wrapper from the existing directory URL.
        let dirWrapper = try FileWrapper(url: wrapperDirURL, options: [])
        // dirWrapper.fileWrappers contains children, if needed for inspection.

        // Create a regular file wrapper in memory.
        let fileData = "Wrapper Data".data(using: .utf8)!
        let fileWrapper = FileWrapper(regularFileWithContents: fileData)
        fileWrapper.preferredFilename = "wrapped.txt"  // Suggested filename on disk.

        // Prepare output directory where the wrapper will be written.
        try fm.createDirectory(at: wrapperOutDirURL,
                               withIntermediateDirectories: true,
                               attributes: nil)

        // Write the wrapper to disk. This will create “wrapped.txt” inside wrapperOutDirURL.
        try fileWrapper.write(to: wrapperOutDirURL,
                              options: .atomic,
                              originalContentsURL: nil)
    } catch {
        print("FileWrapper error: \(error)")
    }

    // ==================== Unsafe Swift String / Array / Dictionary I/O (should be blocked) ====================
    // The following examples intentionally use APIs that might be considered unsafe
    // or restricted in certain environments, such as plugins or sandboxes.

    do {
        print("=== Unsafe Swift I/O examples (String / Array / Dictionary) ===")

        // 1) Direct Swift String file I/O.
        let unsafeStringURL = baseDirURL.appendingPathComponent("Unsafe_String.txt")
        let swiftString = "Unsafe Swift String I/O \(Date())"

        // This convenience write API is very handy but may be disallowed where you must
        // go through approved I/O wrappers only.
        try swiftString.write(to: unsafeStringURL, atomically: true, encoding: .utf8)

        // Reading back using Swift’s high-level String initializer.
        let loadedSwiftString = try String(contentsOf: unsafeStringURL, encoding: .utf8)
        print("Unsafe String read: \(loadedSwiftString)")

        // 2) Array -> PropertyListSerialization
        let unsafeArrayURL = baseDirURL.appendingPathComponent("Unsafe_Array.plist")
        let swiftArray = ["one", "two", "three"]

        // Encoding Swift Array directly into a property list and writing it out.
        // This pattern is fine in normal apps, but here it’s labeled "unsafe"
        // because it avoids the higher-level wrappers that might be mandated.
        let unsafeArrayData = try PropertyListSerialization.data(fromPropertyList: swiftArray,
                                                                 format: .binary,
                                                                 options: 0)
        try unsafeArrayData.write(to: unsafeArrayURL, options: .atomic)
        let loadedArrayData = try Data(contentsOf: unsafeArrayURL)
        print("Unsafe Array plist size: \(loadedArrayData.count)")

        // 3) Dictionary -> PropertyListSerialization
        let unsafeDictURL = baseDirURL.appendingPathComponent("Unsafe_Dictionary.plist")
        let swiftDict: [String: Any] = [
            "key1": "value1",
            "key2": "value2",
            "num":  123
        ]

        let unsafeDictData = try PropertyListSerialization.data(fromPropertyList: swiftDict,
                                                                format: .binary,
                                                                options: 0)
        try unsafeDictData.write(to: unsafeDictURL, options: .atomic)
        let loadedDictData = try Data(contentsOf: unsafeDictURL)
        print("Unsafe Dictionary plist size: \(loadedDictData.count)")

    } catch {
        print("Unsafe Swift I/O error: \(error)")
    }

    // ==================== Safe NSString / NSArray / NSDictionary I/O ====================
    // In contrast to the “unsafe” Swift-native examples above, here we rely on
    // Objective‑C bridged types and their file I/O APIs, which might be whitelisted
    // or recommended in certain environments.[web:16][web:19][web:10]

    do {
        print("=== Safe NSString / NSArray / NSDictionary I/O examples ===")

        // 1) NSString file write/read
        let safeStringURL = baseDirURL.appendingPathComponent("Safe_String.txt")
        let objcString: NSString = "Safe NSString I/O \(Date())" as NSString

        // NSString’s write(to:atomically:encoding:) is a classic Objective‑C API for text files.
        try objcString.write(to: safeStringURL,
                             atomically: true,
                             encoding: String.Encoding.utf8.rawValue)

        do {
            let loadedObjCString = try NSString(contentsOf: safeStringURL,
                                                encoding: String.Encoding.utf8.rawValue)
            print("Safe NSString read: \(loadedObjCString)")
        } catch {
            print("Error reading NSString: \(error)")
        }

        // 2) NSArray file write/read (Property List)
        let safeArrayURL = baseDirURL.appendingPathComponent("Safe_Array.plist")
        let objcArray: NSArray = ["one", "two", "three"]

        // NSArray’s write(to:atomically:) writes a property list representation to disk.
        objcArray.write(to: safeArrayURL, atomically: true)

        if let loadedObjCArray = NSArray(contentsOf: safeArrayURL) {
            print("Safe NSArray read: \(loadedObjCArray)")
        }

        // 3) NSDictionary file write/read (Property List)
        let safeDictURL = baseDirURL.appendingPathComponent("Safe_Dictionary.plist")
        let objcDict: NSDictionary = [
            "key1": "value1",
            "key2": "value2",
            "num": 123
        ]

        // NSDictionary’s write(to:atomically:) also produces a property list on disk.
        objcDict.write(to: safeDictURL, atomically: true)

        if let loadedObjCDict = NSDictionary(contentsOf: safeDictURL) {
            print("Safe NSDictionary read: \(loadedObjCDict)")
        }

    } catch {
        print("Safe Objective-C I/O error: \(error)")
    }
}
