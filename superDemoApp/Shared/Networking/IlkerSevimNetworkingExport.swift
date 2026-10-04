//
//  IlkerSevimNetworkingExport.swift
//  superDemoApp
//
//  Re-exports the published SPM package so app/test files keep using networking
//  types without per-file imports. Canonical sources:
//  https://github.com/redjadet/ilkersevim_networking
//

@_exported import IlkerSevimNetworking

/// Compatibility alias — SDK renamed `AppURLSession` → `DefaultURLSession`.
typealias AppURLSession = DefaultURLSession
