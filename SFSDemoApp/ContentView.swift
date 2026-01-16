import SwiftUI

// MARK: - Enums
enum FileAPI: String, CaseIterable {
    case NSFileManager = "NSFileManager"
    case NSData = "NSData"
    case NSFileHandle = "NSFileHandle"
}
enum CodeLang: String, CaseIterable {
    case Swift = "Swift"
    case ObjectiveC = "Objective-C"
}

struct CodeBlock: Identifiable, Equatable {
    let id = UUID()
    var code: String

    static func == (lhs: CodeBlock, rhs: CodeBlock) -> Bool {
        lhs.id == rhs.id && lhs.code == rhs.code
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var selectedAPI: FileAPI = .NSFileManager
    @State private var selectedLang: CodeLang = .Swift
    @State private var randomData: Data?
    @State private var fileDataFoundation: Data?
    @State private var codeBlocks: [CodeBlock] = []
    @State private var readDataTitle: String = "Read Data"

    @State private var hasRunAppSealing = false   // AppSealing 한 번만 실행용

    private let io = FileIOManager()

    var body: some View {
        GeometryReader { geo in
            let isNarrow = geo.size.width < 600

            ScrollView {
                VStack(spacing: 12) {

                    // MARK: - API & Language Selection
                    if isNarrow {
                        VStack(spacing: 12) {
                            apiButtonsRow
                            langButtonsRow
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    } else {
                        HStack(alignment: .center, spacing: 16) {
                            apiButtonsRow
                            Spacer()
                            langButtonsRow
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    Divider()

                    // MARK: - Buttons ①~④
                    if isNarrow {
                        VStack(spacing: 8) {
                            actionButtons
                        }
                        .padding(.horizontal)
                    } else {
                        HStack(spacing: 8) {
                            actionButtons
                        }
                        .padding(.horizontal)
                    }

                    Divider()

                    // MARK: - Code Output
                    GroupBox(label: Text("Code Output").font(.system(size: 16, weight: .bold))) {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical) {
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(codeBlocks) { block in
                                        HighlightedCodeView(code: block.code, language: selectedLang)
                                            .padding(4)
                                            .background(Color.white)
                                            .cornerRadius(4)
                                            .id(block.id)
                                    }
                                }
                                .padding(4)
                            }
                            .frame(height: 180)
                            .onChange(of: codeBlocks) { _ in
                                if let last = codeBlocks.last {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Hex Comparison
                    GroupBox {
                        if isNarrow {
                            VStack(alignment: .leading, spacing: 20) {
                                originalHexView
                                comparedHexView
                            }
                            .padding(.horizontal, 10)
                        } else {
                            HStack(alignment: .top, spacing: 20) {
                                originalHexView
                                comparedHexView
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    // MARK: - Path
                    Text("Path: \(io.getFileURL().path)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .frame(maxWidth: 700, alignment: .top)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .onAppear {
            runAppSealingOnce()
        }
    }

    // MARK: - AppSealing (SwiftUI에서 viewDidAppear 대체)
    private func runAppSealingOnce() {
        guard !hasRunAppSealing else { return }
        hasRunAppSealing = true

        //############################################################## AppSealing Code-Part BEGIN: DO NOT MODIFY THIS LINE !!!
        #if true  //--------------------------------------- APPSEALING-GetDeviceID [BEGIN] : DO NOT REMOVE THIS COMMENT !!!
        let _instAppSealing_auto_generated1: AppSealingInterface = AppSealingInterface()
        let _appSealingDeviceID_auto_generated = String(
            cString: _instAppSealing_auto_generated1._GetAppSealingDeviceID()
        )
        let _appsealing_msg1 = "\n\n* AppSealing Device ID : "
        print(_appsealing_msg1 + _appSealingDeviceID_auto_generated + "\n\n")
        #endif    //--------------------------------------- APPSEALING-GetDeviceID [END] : DO NOT REMOVE THIS COMMENT !!!

        let inst = AppSealingInterface()
        inst._IsAbnormalEnvironmentDetectedAsync { code in
            guard code > 0 else { return }
            var msg = "Abnormal Environment Detected !!"
            if code & kAppSealingErrorJailbreakDetected != 0 { msg += "\n - Jailbroken" }
            if code & kAppSealingErrorDRMDecrypted != 0 { msg += "\n - Executable is not encrypted" }
            if code & kAppSealingErrorDebugAttached != 0 { msg += "\n - App is debugged" }
            if code & (kAppSealingErrorHashInfoCorrupted | kAppSealingErrorHashModified) != 0 {
                msg += "\n - App integrity corrupted"
            }
            if code & (kAppSealingErrorCodesignCorrupted | kAppSealingErrorExecutableCorrupted) != 0 {
                msg += "\n - App executable has corrupted"
            }
            if code & kAppSealingErrorCertificateChanged != 0 {
                msg += "\n - App has re-signed"
            }
            if code & kAppSealingErrorBlacklistCorrupted != 0 {
                msg += "\n - Blacklist/Whitelist has corrupted or missing"
            }
            if code & kAppSealingErrorCheatToolDetected != 0 {
                msg += "\n - Cheat tool has detected"
            }

            DispatchQueue.main.async {
                // SwiftUI 뷰에서 직접 present 못하므로, rootViewController 통해 경고창 표시[web:77]
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = scene.windows.first?.rootViewController {
                    let alert = UIAlertController(
                        title: "AppSealing Security\0x1\0x1\0x1\0x1",
                        message: msg,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
                        #if !DEBUG
                        _exit(0)
                        #endif
                    })
                    rootVC.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Sub rows

    private var apiButtonsRow: some View {
        HStack(spacing: 8) {
            ForEach(FileAPI.allCases, id: \.self) { api in
                Button(apiDisplayName(api)) {
                    selectedAPI = api
                    resetForSelection()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selectedAPI == api ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(selectedAPI == api ? Color.green : Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
    }

    private var langButtonsRow: some View {
        HStack(spacing: 8) {
            ForEach(CodeLang.allCases, id: \.self) { lang in
                Button(lang.rawValue) {
                    selectedLang = lang
                    resetForSelection()
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(selectedLang == lang ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(selectedLang == lang ? Color.cyan : Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }

    private var actionButtons: some View {
        Group {
            Button("① Generate Random Data") { generateRandomData() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

            Button("② Write (\(selectedLang.rawValue))") { writeFile() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

            Button("③ Read POSIX") { readPOSIX() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

            Button("④ Read (\(selectedLang.rawValue))") { readFoundation() }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
        }
        .font(.system(size: 14, weight: .semibold))
    }

    // MARK: - Hex views

    private var originalHexView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Original Data")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let randomData {
                let lines = HexFormatter.hexColumnLines(randomData)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.35, blue: 0.0))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer().frame(height: 220)
            }
        }
    }

    private var comparedHexView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(readDataTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let randomData, let fileDataFoundation {
                let maxCount = max(randomData.count, fileDataFoundation.count)
                let lines: [AttributedString] = stride(from: 0, to: maxCount, by: 16).map { offset in
                    var line = AttributedString()
                    for i in 0..<16 {
                        let idx = offset + i
                        guard idx < maxCount else { break }
                        let orig = idx < randomData.count ? String(format: "%02X", randomData[idx]) : "--"
                        let comp = idx < fileDataFoundation.count ? String(format: "%02X", fileDataFoundation[idx]) : "--"
                        var token = AttributedString(comp + " ")
                        token.foregroundColor = (comp == orig)
                        ? Color(red: 0.0, green: 0.35, blue: 0.0)
                        : .red
                        line.append(token)
                    }
                    return line
                }
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer().frame(height: 220)
            }
        }
    }

    // MARK: - Helpers

    func apiDisplayName(_ api: FileAPI) -> String {
        if selectedLang == .Swift {
            switch api {
            case .NSFileManager: return "FileManager"
            case .NSData:        return "NSData"
            case .NSFileHandle:  return "FileHandle"
            }
        } else {
            return api.rawValue
        }
    }

    func resetForSelection() {
        codeBlocks = []
        fileDataFoundation = nil
        randomData = nil
        readDataTitle = "Read Data"
    }

    func appendCodeBlock(_ code: String) {
        if let idx = codeBlocks.firstIndex(where: { _ in true }) {
            codeBlocks[idx].code += ( "\n" + code )
        } else {
            codeBlocks.append(CodeBlock(code: code))
        }
    }

    // MARK: - Data Operations

    func generateRandomData() {
        let url = io.getFileURL()
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        randomData = RandomDataGenerator.generate(size: 256)
        let code = selectedLang == .Swift
        ? "let nsData = Data(( 0..<256 ).map { _ in UInt8.random( in: 0...255 ) })"
        : "NSData *nsData = [NSData dataWithBytes:random length:256];"
        appendCodeBlock(code)
    }

    func writeFile() {
        guard let nsData = randomData as NSData? else { return }
        let url = io.getFileURL()
        let fileNameOnly = url.lastPathComponent
        var code: String = ""

        do {
            switch (selectedAPI, selectedLang) {
            case (.NSFileManager, .Swift):
                FileManager.default.createFile(atPath: url.path, contents: nsData as Data, attributes: nil)
                code = "FileManager.default.createFile( atPath: \"\(fileNameOnly)\", contents: nsData, attributes: nil )"

            case (.NSData, .Swift):
                try (nsData as NSData).write(to: url)
                code = "try ( nsData as NSData ).write( to: URL(fileURLWithPath: \"\(fileNameOnly)\" ))"

            case (.NSFileHandle, .Swift):
                if !FileManager.default.fileExists(atPath: url.path) {
                    FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
                }
                do {
                    let handle = try FileHandle(forWritingTo: url)
                    handle.write(nsData as Data)
                    handle.closeFile()
                    code = """
                    let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: "\(fileNameOnly)"))
                    handle.write(nsData as Data)
                    handle.closeFile()
                    """
                } catch {
                    print("NSFileHandle write error: \(error)")
                }

            case (_, .ObjectiveC):
                let success = FileOperations.write(nsData as Data, withAPI: selectedAPI.rawValue, toPath: url.path)
                if !success { print("!!!! Write failed") }

                switch selectedAPI {
                case .NSFileManager:
                    code = "[[NSFileManager defaultManager] createFileAtPath:@\"\(fileNameOnly)\" contents:nsData attributes:nil];"
                case .NSData:
                    code = "[nsData writeToFile:@\"\(fileNameOnly)\" atomically:YES];"
                case .NSFileHandle:
                    code = """
                    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:@\"\(fileNameOnly)\"];
                    [handle writeData:nsData];
                    [handle closeFile];
                    """
                }
            }

            appendCodeBlock(code)
        } catch { }
    }

    func readFoundation() {
        let url = io.getFileURL()
        let fileNameOnly = url.lastPathComponent
        var data: NSData?
        var code: String = ""

        do {
            switch (selectedAPI, selectedLang) {
            case (.NSFileManager, .Swift):
                data = FileManager.default.contents(atPath: url.path) as NSData?
                code = "let nsData = FileManager.default.contents( atPath: \"\(fileNameOnly)\" ) as NSData?"

            case (.NSData, .Swift):
                data = try NSData(contentsOf: url)
                code = "let nsData = NSData( contentsOfFile: \"\(fileNameOnly)\" )"

            case (.NSFileHandle, .Swift):
                let handle = try FileHandle(forReadingFrom: url)
                data = handle.readDataToEndOfFile() as NSData
                handle.closeFile()
                code = """
                let handle = try FileHandle( forReadingFrom: URL( fileURLWithPath: "\(fileNameOnly)" ))
                let nsData = handle.readDataToEndOfFile() as NSData
                handle.closeFile()
                """

            case (_, .ObjectiveC):
                let dataRead = FileOperations.readData(withAPI: selectedAPI.rawValue, fromPath: url.path)
                data = dataRead as NSData?

                switch selectedAPI {
                case .NSFileManager:
                    code = "NSData *nsData = [[NSFileManager defaultManager] contentsAtPath:@\"\(fileNameOnly)\"];"
                case .NSData:
                    code = "NSData *nsData = [NSData dataWithContentsOfFile:@\"\(fileNameOnly)\"];"
                case .NSFileHandle:
                    code = """
                    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:@\"\(fileNameOnly)\"];
                    NSData *nsData = [handle readDataToEndOfFile];
                    [handle closeFile];
                    """
                }
            }

            fileDataFoundation = data as Data?
            readDataTitle = "Read Data (\(selectedLang.rawValue))"
            appendCodeBlock(code)
        } catch { }
    }

    func readPOSIX() {
        let url = io.getFileURL()
        var buffer = [UInt8](repeating: 0, count: 256)

        if let f = fopen(url.path, "rb") {
            var headerBuffer = [UInt8](repeating: 0, count: 8)
            fread(&headerBuffer, 1, headerBuffer.count, f)

            let asefMagic: [UInt8] = [0x41, 0x53, 0x45, 0x46, 0x01, 0x02, 0x03, 0x04]
            let hasHeader = headerBuffer == asefMagic

            if hasHeader {
                fseek(f, 160, SEEK_SET)
            } else {
                fseek(f, 0, SEEK_SET)
            }
            let bytesRead = fread(&buffer, 1, buffer.count, f)
            fclose(f)
            let data = NSData(bytes: buffer, length: bytesRead)
            fileDataFoundation = data as Data?

            let fileNameOnly = url.lastPathComponent
            let code: String

            switch selectedLang {
            case .Swift:
                code = """
                var buffer = [UInt8](repeating: 0, count: 256)
                let file = fopen( "\(fileNameOnly)", "rb" )
                fseek( file, header_size, SEEK_SET )
                fread( &buffer, 1, buffer.count, file )
                fclose( file )
                """
            case .ObjectiveC:
                code = """
                unsigned char buffer[256];
                FILE *file = fopen( "\(fileNameOnly)", "rb" );
                fseek( file, header_size, SEEK_SET )
                fread( buffer, 1, 256, file );
                fclose( file );
                """
            }

            appendCodeBlock(code)
            readDataTitle = "Read Data (POSIX - without header)"
        }
    }
}

// MARK: - FileIOManager
final class FileIOManager {
    private let fileName = "demo.bin"
    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName)
    }
    func getFileURL() -> URL { fileURL }
}

// MARK: - HexFormatter
enum HexFormatter {
    static func hexColumnLines(_ data: Data) -> [String] {
        stride(from: 0, to: data.count, by: 16).map { offset in
            data[offset..<min(offset+16, data.count)]
                .map { String(format: "%02X", $0) }
                .joined(separator: " ")
        }
    }
}

// MARK: - RandomDataGenerator
enum RandomDataGenerator {
    static func generate(size: Int) -> Data {
        Data((0..<size).map { _ in UInt8.random(in: 0...255) })
    }
}

// MARK: - HighlightedCodeView
struct HighlightedCodeView: View {
    let code: String
    let language: CodeLang

    var body: some View {
        ScrollView(.horizontal) {
            Text(styledCode())
                .font(.system(size: 12, design: .monospaced))
                .lineSpacing(4)
                .textSelection(.enabled)
        }
    }

    func styledCode() -> AttributedString {
        var attrStr = AttributedString(code)

        switch language {
        case .Swift:
            let swiftKeywords = [
                "let","var","func","class","struct","enum","protocol","extension",
                "if","else","switch","case","default","for","while","repeat","in",
                "return","break","continue","try","catch","throw","do","as","is",
                "nil","self","super"
            ]
            highlightWords(swiftKeywords, color: .blue, bold: true, in: &attrStr)

            let swiftClassMethods: [String: [String]] = [
                "FileManager": ["createFile", "contents", "removeItem", "copyItem", "moveItem"],
                "Data": ["write", "append", "subdata", "count"],
                "String": ["hasPrefix", "hasSuffix", "uppercased", "lowercased"],
                "NSData": ["dataWithContentsOfFile","writeToFile","length"],
                "FileHandle": ["forWritingTo", "forReadingFrom"]
            ]
            for (cls, methods) in swiftClassMethods {
                highlightWords([cls], color: .indigo, bold: true, in: &attrStr)
                for method in methods {
                    highlightPattern("\\.\(method)\\s*\\(", color: .blue, bold: true, in: &attrStr)
                }
            }

            highlightWords(
                ["fopen","fread","fwrite","fclose","ftell","fseek","rewind"],
                color: .indigo, bold: true, in: &attrStr
            )

        case .ObjectiveC:
            let objcKeywords = [
                "return","if","else","for","while","break","continue","unsigned","char",
                "FILE","void","@interface","@implementation","@end"
            ]
            highlightWords(objcKeywords, color: .blue, bold: true, in: &attrStr)

            let objcClassMethods: [String: [String]] = [
                "NSFileManager": ["createFileAtPath","contentsAtPath","removeItemAtPath","copyItemAtPath","moveItemAtPath"],
                "NSData": ["dataWithContentsOfFile","writeToFile","length"],
                "NSFileHandle": ["fileHandleForReadingAtPath","fileHandleForWritingAtPath",
                                 "readDataToEndOfFile","writeData","closeFile"]
            ]
            for (cls, methods) in objcClassMethods {
                highlightWords([cls], color: .indigo, bold: true, in: &attrStr)
                for method in methods {
                    highlightWords([method], color: .blue, bold: true, in: &attrStr)
                }
            }

            highlightWords(
                ["fopen","fread","fwrite","fclose","ftell","fseek","rewind"],
                color: .indigo, bold: true, in: &attrStr
            )
        }

        highlightPattern("\".*?\"", color: .purple, bold: false, in: &attrStr)
        return attrStr
    }

    private func highlightWords(
        _ words: [String],
        color: Color,
        bold: Bool,
        in attrStr: inout AttributedString
    ) {
        let pattern = "\\b(" + words.joined(separator: "|") + ")\\b"
        highlightPattern(pattern, color: color, bold: bold, in: &attrStr)
    }

    private func highlightPattern(
        _ pattern: String,
        color: Color?,
        bold: Bool,
        in attrStr: inout AttributedString
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let base = String(attrStr.characters)
        let nsStr = NSString(string: base)
        let matches = regex.matches(in: base, range: NSRange(location: 0, length: nsStr.length))
        for match in matches {
            let range = match.range(at: 0)
            if let swiftRange = Range(range, in: attrStr) {
                if let color = color { attrStr[swiftRange].foregroundColor = color }
                if bold {
                    attrStr[swiftRange].font = .system(
                        size: 14,
                        weight: .bold,
                        design: .monospaced
                    )
                }
            }
        }
    }
}
