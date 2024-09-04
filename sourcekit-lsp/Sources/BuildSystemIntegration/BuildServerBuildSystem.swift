//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import BuildServerProtocol
import Foundation
import LanguageServerProtocol
import LanguageServerProtocolJSONRPC
import SKLogging
import SKSupport
import SwiftExtensions
import ToolchainRegistry

import struct TSCBasic.AbsolutePath
import protocol TSCBasic.FileSystem
import struct TSCBasic.FileSystemError
import func TSCBasic.getEnvSearchPaths
import var TSCBasic.localFileSystem
import func TSCBasic.lookupExecutablePath
import func TSCBasic.resolveSymlinks

enum BuildServerTestError: Error {
  case executableNotFound(String)
}

func executable(_ name: String) -> String {
  #if os(Windows)
  guard !name.hasSuffix(".exe") else { return name }
  return "\(name).exe"
  #else
  return name
  #endif
}

/// A `BuildSystem` based on communicating with a build server
///
/// Provides build settings from a build server launched based on a
/// `buildServer.json` configuration file provided in the repo root.
package actor BuildServerBuildSystem: MessageHandler {
  package let projectRoot: AbsolutePath
  let serverConfig: BuildServerConfig

  var buildServer: JSONRPCConnection?

  /// The queue on which all messages that originate from the build server are
  /// handled.
  ///
  /// These are requests and notifications sent *from* the build server,
  /// not replies from the build server.
  ///
  /// This ensures that messages from the build server are handled in the order
  /// they were received. Swift concurrency does not guarentee in-order
  /// execution of tasks.
  package let bspMessageHandlingQueue = AsyncQueue<Serial>()

  let searchPaths: [AbsolutePath]

  package private(set) var indexDatabasePath: AbsolutePath?
  package private(set) var indexStorePath: AbsolutePath?

  /// Delegate to handle any build system events.
  package weak var delegate: BuildSystemDelegate?

  /// - Note: Needed to set the delegate from a different actor isolation context
  package func setDelegate(_ delegate: BuildSystemDelegate?) async {
    self.delegate = delegate
  }

  /// The build settings that have been received from the build server.
  private var buildSettings: [DocumentURI: FileBuildSettings] = [:]

  package init(
    projectRoot: AbsolutePath,
    fileSystem: FileSystem = localFileSystem
  ) async throws {
    let configPath = projectRoot.appending(component: "buildServer.json")
    let config = try loadBuildServerConfig(path: configPath, fileSystem: fileSystem)
    #if os(Windows)
    self.searchPaths =
      getEnvSearchPaths(
        pathString: ProcessInfo.processInfo.environment["Path"],
        currentWorkingDirectory: fileSystem.currentWorkingDirectory
      )
    #else
    self.searchPaths =
      getEnvSearchPaths(
        pathString: ProcessInfo.processInfo.environment["PATH"],
        currentWorkingDirectory: fileSystem.currentWorkingDirectory
      )
    #endif
    self.projectRoot = projectRoot
    self.serverConfig = config
    try await self.initializeBuildServer()
  }

  /// Creates a build system using the Build Server Protocol config.
  ///
  /// - Returns: nil if `projectRoot` has no config or there is an error parsing it.
  package init?(projectRoot: AbsolutePath?) async {
    guard let projectRoot else { return nil }

    do {
      try await self.init(projectRoot: projectRoot)
    } catch is FileSystemError {
      // config file was missing, no build server for this workspace
      return nil
    } catch {
      logger.fault("Failed to start build server: \(error.forLogging)")
      return nil
    }
  }

  deinit {
    if let buildServer = self.buildServer {
      _ = buildServer.send(ShutdownBuild()) { result in
        if let error = result.failure {
          logger.fault("Error shutting down build server: \(error.forLogging)")
        }
        buildServer.send(ExitBuildNotification())
        buildServer.close()
      }
    }
  }

  private func initializeBuildServer() async throws {
    var serverPath = try AbsolutePath(validating: serverConfig.argv[0], relativeTo: projectRoot)
    var flags = Array(serverConfig.argv[1...])
    if serverPath.suffix == ".py" {
      flags = [serverPath.pathString] + flags
      guard
        let interpreterPath =
          lookupExecutablePath(
            filename: executable("python3"),
            searchPaths: searchPaths
          )
          ?? lookupExecutablePath(
            filename: executable("python"),
            searchPaths: searchPaths
          )
      else {
        throw BuildServerTestError.executableNotFound("python3")
      }

      serverPath = interpreterPath
    }
    let languages = [
      Language.c,
      Language.cpp,
      Language.objective_c,
      Language.objective_cpp,
      Language.swift,
    ]

    let initializeRequest = InitializeBuild(
      displayName: "SourceKit-LSP",
      version: "1.0",
      bspVersion: "2.0",
      rootUri: URI(self.projectRoot.asURL),
      capabilities: BuildClientCapabilities(languageIds: languages)
    )

    let buildServer = try makeJSONRPCBuildServer(client: self, serverPath: serverPath, serverFlags: flags)
    let response = try await buildServer.send(initializeRequest)
    buildServer.send(InitializedBuildNotification())
    logger.log("Initialized build server \(response.displayName)")

    // see if index store was set as part of the server metadata
    if let indexDbPath = readReponseDataKey(data: response.data, key: "indexDatabasePath") {
      self.indexDatabasePath = try AbsolutePath(validating: indexDbPath, relativeTo: self.projectRoot)
    }
    if let indexStorePath = readReponseDataKey(data: response.data, key: "indexStorePath") {
      self.indexStorePath = try AbsolutePath(validating: indexStorePath, relativeTo: self.projectRoot)
    }
    self.buildServer = buildServer
  }

  /// Handler for notifications received **from** the builder server, ie.
  /// the build server has sent us a notification.
  ///
  /// We need to notify the delegate about any updated build settings.
  package nonisolated func handle(_ params: some NotificationType) {
    logger.info(
      """
      Received notification from build server:
      \(params.forLogging)
      """
    )
    bspMessageHandlingQueue.async {
      if let params = params as? BuildTargetsChangedNotification {
        await self.handleBuildTargetsChanged(params)
      } else if let params = params as? FileOptionsChangedNotification {
        await self.handleFileOptionsChanged(params)
      }
    }
  }

  /// Handler for requests received **from** the build server.
  ///
  /// We currently can't handle any requests sent from the build server to us.
  package nonisolated func handle<R: RequestType>(
    _ params: R,
    id: RequestID,
    reply: @escaping (LSPResult<R.Response>) -> Void
  ) {
    logger.info(
      """
      Received request from build server:
      \(params.forLogging)
      """
    )
    reply(.failure(ResponseError.methodNotFound(R.method)))
  }

  func handleBuildTargetsChanged(
    _ notification: BuildTargetsChangedNotification
  ) async {
    await self.delegate?.buildTargetsChanged(notification.changes)
  }

  func handleFileOptionsChanged(
    _ notification: FileOptionsChangedNotification
  ) async {
    let result = notification.updatedOptions
    let settings = FileBuildSettings(
      compilerArguments: result.options,
      workingDirectory: result.workingDirectory
    )
    await self.buildSettingsChanged(for: notification.uri, settings: settings)
  }

  /// Record the new build settings for the given document and inform the delegate
  /// about the changed build settings.
  private func buildSettingsChanged(for document: DocumentURI, settings: FileBuildSettings?) async {
    buildSettings[document] = settings
    await self.delegate?.fileBuildSettingsChanged([document])
  }
}

private func readReponseDataKey(data: LSPAny?, key: String) -> String? {
  if case .dictionary(let dataDict)? = data,
    case .string(let stringVal)? = dataDict[key]
  {
    return stringVal
  }

  return nil
}

extension BuildServerBuildSystem: BuildSystem {
  package nonisolated var supportsPreparation: Bool { false }

  /// The build settings for the given file.
  ///
  /// Returns `nil` if no build settings have been received from the build
  /// server yet or if no build settings are available for this file.
  package func buildSettings(
    for document: DocumentURI,
    in target: ConfiguredTarget,
    language: Language
  ) async -> FileBuildSettings? {
    return buildSettings[document]
  }

  package func defaultLanguage(for document: DocumentURI) async -> Language? {
    return nil
  }

  package func toolchain(for uri: DocumentURI, _ language: Language) async -> Toolchain? {
    return nil
  }

  package func configuredTargets(for document: DocumentURI) async -> [ConfiguredTarget] {
    return [ConfiguredTarget(targetID: "dummy", runDestinationID: "dummy")]
  }

  package func generateBuildGraph(allowFileSystemWrites: Bool) {}

  package func topologicalSort(of targets: [ConfiguredTarget]) async -> [ConfiguredTarget]? {
    return nil
  }

  package func targets(dependingOn targets: [ConfiguredTarget]) -> [ConfiguredTarget]? {
    return nil
  }

  package func prepare(
    targets: [ConfiguredTarget],
    logMessageToIndexLog: @Sendable (_ taskID: IndexTaskID, _ message: String) -> Void
  ) async throws {
    throw PrepareNotSupportedError()
  }

  package func registerForChangeNotifications(for uri: DocumentURI) {
    let request = RegisterForChanges(uri: uri, action: .register)
    _ = self.buildServer?.send(request) { result in
      if let error = result.failure {
        logger.error("Error registering \(uri): \(error.forLogging)")

        Task {
          // BuildServer registration failed, so tell our delegate that no build
          // settings are available.
          await self.buildSettingsChanged(for: uri, settings: nil)
        }
      }
    }
  }

  /// Unregister the given file for build-system level change notifications, such as command
  /// line flag changes, dependency changes, etc.
  package func unregisterForChangeNotifications(for uri: DocumentURI) {
    let request = RegisterForChanges(uri: uri, action: .unregister)
    _ = self.buildServer?.send(request) { result in
      if let error = result.failure {
        logger.error("Error unregistering \(uri.forLogging): \(error.forLogging)")
      }
    }
  }

  package func filesDidChange(_ events: [FileEvent]) {}

  package func fileHandlingCapability(for uri: DocumentURI) -> FileHandlingCapability {
    guard
      let fileUrl = uri.fileURL,
      let path = try? AbsolutePath(validating: fileUrl.path)
    else {
      return .unhandled
    }

    // TODO: We should not make any assumptions about which files the build server can handle.
    // Instead we should query the build server which files it can handle
    // (https://github.com/swiftlang/sourcekit-lsp/issues/492).

    if projectRoot.isAncestorOfOrEqual(to: path) {
      return .handled
    }

    if let realpath = try? resolveSymlinks(path), realpath != path, projectRoot.isAncestorOfOrEqual(to: realpath) {
      return .handled
    }

    return .unhandled
  }

  package func sourceFiles() async -> [SourceFileInfo] {
    // BuildServerBuildSystem does not support syntactic test discovery or background indexing.
    // (https://github.com/swiftlang/sourcekit-lsp/issues/1173).
    return []
  }

  package func addSourceFilesDidChangeCallback(_ callback: @escaping () async -> Void) {
    // BuildServerBuildSystem does not support syntactic test discovery or background indexing.
    // (https://github.com/swiftlang/sourcekit-lsp/issues/1173).
  }
}

private func loadBuildServerConfig(path: AbsolutePath, fileSystem: FileSystem) throws -> BuildServerConfig {
  let decoder = JSONDecoder()
  let fileData = try fileSystem.readFileContents(path).contents
  return try decoder.decode(BuildServerConfig.self, from: Data(fileData))
}

struct BuildServerConfig: Codable {
  /// The name of the build tool.
  let name: String

  /// The version of the build tool.
  let version: String

  /// The bsp version of the build tool.
  let bspVersion: String

  /// A collection of languages supported by this BSP server.
  let languages: [String]

  /// Command arguments runnable via system processes to start a BSP server.
  let argv: [String]
}

private func makeJSONRPCBuildServer(
  client: MessageHandler,
  serverPath: AbsolutePath,
  serverFlags: [String]?
) throws -> JSONRPCConnection {
  let clientToServer = Pipe()
  let serverToClient = Pipe()

  let connection = JSONRPCConnection(
    name: "build server",
    protocol: BuildServerProtocol.bspRegistry,
    inFD: serverToClient.fileHandleForReading,
    outFD: clientToServer.fileHandleForWriting
  )

  connection.start(receiveHandler: client) {
    // Keep the pipes alive until we close the connection.
    withExtendedLifetime((clientToServer, serverToClient)) {}
  }
  let process = Foundation.Process()
  process.executableURL = serverPath.asURL
  process.arguments = serverFlags
  process.standardOutput = serverToClient
  process.standardInput = clientToServer
  process.terminationHandler = { process in
    logger.log(
      level: process.terminationReason == .exit ? .default : .error,
      "Build server exited: \(String(reflecting: process.terminationReason)) \(process.terminationStatus)"
    )
    connection.close()
  }
  try process.run()
  return connection
}
