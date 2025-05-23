//
//  CameraManager.swift
//  Glimpsify iOS
//
//  Created by Rudrank Riyam on 5/23/25.
//

import AVFoundation
import SwiftUI
import UIKit

@Observable
class CameraManager: NSObject {
  var authorizationStatus: AVAuthorizationStatus = .notDetermined
  var isSessionRunning = false
  var capturedImage: UIImage?
  var error: CameraError?

  private var captureSession: AVCaptureSession?
  private var photoOutput: AVCapturePhotoOutput?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

  override init() {
    super.init()
    authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
  }

  func requestPermission() async -> Bool {
    guard authorizationStatus == .notDetermined else {
      return authorizationStatus == .authorized
    }

    let granted = await AVCaptureDevice.requestAccess(for: .video)
    await MainActor.run {
      authorizationStatus = granted ? .authorized : .denied
    }
    return granted
  }

  func setupCamera() async {
    guard await requestPermission() else {
      await MainActor.run {
        error = .permissionDenied
      }
      return
    }

    await MainActor.run {
      error = nil
    }

    guard
      let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    else {
      await MainActor.run {
        error = .cameraUnavailable
      }
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: camera)
      let session = AVCaptureSession()

      session.beginConfiguration()

      if session.canAddInput(input) {
        session.addInput(input)
      } else {
        throw CameraError.configurationFailed
      }

      let output = AVCapturePhotoOutput()
      if session.canAddOutput(output) {
        session.addOutput(output)
      } else {
        throw CameraError.configurationFailed
      }

      session.commitConfiguration()

      await MainActor.run {
        captureSession = session
        photoOutput = output
      }

    } catch {
      await MainActor.run {
        self.error = .configurationFailed
      }
    }
  }

  func startSession() {
    guard let session = captureSession else { return }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      session.startRunning()

      DispatchQueue.main.async {
        self?.isSessionRunning = session.isRunning
      }
    }
  }

  func stopSession() {
    guard let session = captureSession else { return }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      session.stopRunning()

      DispatchQueue.main.async {
        self?.isSessionRunning = false
      }
    }
  }

  func capturePhoto() {
    guard let photoOutput = photoOutput else {
      error = .captureSessionNotSetup
      return
    }

    let settings = AVCapturePhotoSettings()
    settings.flashMode = .auto

    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
    guard let session = captureSession else { return nil }

    if videoPreviewLayer == nil {
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
      videoPreviewLayer?.videoGravity = .resizeAspectFill
    }

    return videoPreviewLayer
  }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
  func photoOutput(
    _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
  ) {
    if let error = error {
      DispatchQueue.main.async {
        self.error = .captureFailed(error.localizedDescription)
      }
      return
    }

    guard let imageData = photo.fileDataRepresentation(),
      let image = UIImage(data: imageData)
    else {
      DispatchQueue.main.async {
        self.error = .imageProcessingFailed
      }
      return
    }

    DispatchQueue.main.async {
      self.capturedImage = image
      self.error = nil
    }
  }
}

// MARK: - Camera Error Types

enum CameraError: LocalizedError {
  case permissionDenied
  case cameraUnavailable
  case configurationFailed
  case captureSessionNotSetup
  case captureFailed(String)
  case imageProcessingFailed

  var errorDescription: String? {
    switch self {
    case .permissionDenied:
      return "Camera permission denied. Please enable camera access in Settings."
    case .cameraUnavailable:
      return "Camera is not available on this device."
    case .configurationFailed:
      return "Failed to configure camera session."
    case .captureSessionNotSetup:
      return "Camera session is not properly set up."
    case .captureFailed(let message):
      return "Failed to capture photo: \(message)"
    case .imageProcessingFailed:
      return "Failed to process captured image."
    }
  }
}
