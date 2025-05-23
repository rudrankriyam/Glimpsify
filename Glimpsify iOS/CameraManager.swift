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
  var currentFlashMode: AVCaptureDevice.FlashMode = .off
  var currentCameraPosition: AVCaptureDevice.Position = .back

  private var captureSession: AVCaptureSession?
  private var photoOutput: AVCapturePhotoOutput?
  private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  private var currentCameraInput: AVCaptureDeviceInput?

  // Computed property for CameraView compatibility
  var isAuthorized: Bool {
    authorizationStatus == .authorized
  }

  // Computed property for CameraView compatibility
  var previewLayer: AVCaptureVideoPreviewLayer? {
    return getPreviewLayer()
  }

  // Check if flash is available on current camera
  var isFlashAvailable: Bool {
    guard let currentDevice = currentCameraInput?.device else { return false }
    return currentDevice.hasFlash
  }

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
      let camera = AVCaptureDevice.default(
        .builtInWideAngleCamera, for: .video, position: currentCameraPosition)
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

      // Set session preset for better quality
      if session.canSetSessionPreset(.photo) {
        session.sessionPreset = .photo
      }

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
        currentCameraInput = input

        // Create preview layer immediately after session setup
        if videoPreviewLayer == nil {
          videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
          videoPreviewLayer?.videoGravity = .resizeAspectFill
        } else {
          videoPreviewLayer?.session = session
        }
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
      if !session.isRunning {
        session.startRunning()
      }

      DispatchQueue.main.async {
        self?.isSessionRunning = session.isRunning
      }
    }
  }

  func stopSession() {
    guard let session = captureSession else { return }

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      if session.isRunning {
        session.stopRunning()
      }

      DispatchQueue.main.async {
        self?.isSessionRunning = false
      }
    }
  }

  func setFlashMode(_ flashMode: AVCaptureDevice.FlashMode) {
    currentFlashMode = flashMode

    // Configure the actual camera device flash mode
    guard let currentDevice = currentCameraInput?.device else { return }

    do {
      try currentDevice.lockForConfiguration()
      if currentDevice.hasFlash {
        // Flash mode will be set when capturing photo via AVCapturePhotoSettings
      }
      currentDevice.unlockForConfiguration()
    } catch {
      print("Error configuring flash: \(error)")
    }
  }

  func flipCamera() {
    guard let session = captureSession else { return }

    let newPosition: AVCaptureDevice.Position = currentCameraPosition == .back ? .front : .back

    guard
      let newCamera = AVCaptureDevice.default(
        .builtInWideAngleCamera, for: .video, position: newPosition)
    else {
      print("Camera not available for position: \(newPosition)")
      return
    }

    do {
      let newInput = try AVCaptureDeviceInput(device: newCamera)

      session.beginConfiguration()

      // Remove the current input
      if let currentInput = currentCameraInput {
        session.removeInput(currentInput)
      }

      // Add the new input
      if session.canAddInput(newInput) {
        session.addInput(newInput)
        currentCameraInput = newInput
        currentCameraPosition = newPosition
      } else {
        // Re-add the old input if new one fails
        if let oldInput = currentCameraInput, session.canAddInput(oldInput) {
          session.addInput(oldInput)
        }
        print("Cannot add new camera input")
      }

      session.commitConfiguration()
    } catch {
      print("Error switching camera: \(error)")
    }
  }

  func capturePhoto() {
    guard let photoOutput = photoOutput else {
      error = .captureSessionNotSetup
      return
    }

    let settings = AVCapturePhotoSettings()

    // Only set flash mode if the photoOutput supports it
    if let currentDevice = currentCameraInput?.device,
      currentDevice.hasFlash,
      photoOutput.supportedFlashModes.contains(currentFlashMode)
    {
      settings.flashMode = currentFlashMode
    } else {
      settings.flashMode = .off
    }

    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  // New method with completion handler for CameraView compatibility
  func capturePhoto(completion: @escaping (UIImage?) -> Void) {
    guard let photoOutput = photoOutput else {
      error = .captureSessionNotSetup
      completion(nil)
      return
    }

    let settings = AVCapturePhotoSettings()

    // Only set flash mode if the photoOutput supports it
    if let currentDevice = currentCameraInput?.device,
      currentDevice.hasFlash,
      photoOutput.supportedFlashModes.contains(currentFlashMode)
    {
      settings.flashMode = currentFlashMode
    } else {
      settings.flashMode = .off
    }

    // Store completion handler for delegate callback
    self.captureCompletion = completion
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  private var captureCompletion: ((UIImage?) -> Void)?

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
        self.captureCompletion?(nil)
        self.captureCompletion = nil
      }
      return
    }

    guard let imageData = photo.fileDataRepresentation() else {
      DispatchQueue.main.async {
        self.error = .imageProcessingFailed
        self.captureCompletion?(nil)
        self.captureCompletion = nil
      }
      return
    }

    guard let image = UIImage(data: imageData) else {
      DispatchQueue.main.async {
        self.error = .imageProcessingFailed
        self.captureCompletion?(nil)
        self.captureCompletion = nil
      }
      return
    }

    DispatchQueue.main.async {
      self.capturedImage = image
      self.error = nil
      self.captureCompletion?(image)
      self.captureCompletion = nil
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
