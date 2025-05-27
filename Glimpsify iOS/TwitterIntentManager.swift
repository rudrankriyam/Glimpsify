//
//  TwitterIntentManager.swift
//  Glimpsify iOS
//
//  Created by AI Assistant on 5/27/25.
//

import UIKit
import SwiftUI

@MainActor
@Observable
final class TwitterIntentManager {
    private var isPresenting = false
    
    /// Opens Twitter app with pre-filled tweet containing text and image
    func shareToTwitter(text: String, image: UIImage) async {
        // Use the iOS share sheet which includes Twitter as an option
        // This is the recommended approach for sharing images with text
        await shareWithActivitySheet(text: text, image: image)
    }
    
    /// Opens Twitter app with just text (no image)
    func shareTextToTwitter(text: String) async {
        // For better user experience, use activity sheet for text-only sharing too
        // This provides more sharing options and is more reliable
        await shareWithActivitySheet(text: text, image: nil)
    }
    
    /// Creates a Twitter intent URL for web sharing (alternative method)
    func openTwitterWebIntent(text: String) async {
        let tweetText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let twitterWebURL = URL(string: "https://twitter.com/intent/tweet?text=\(tweetText)") {
            await UIApplication.shared.open(twitterWebURL)
        }
    }
    
    private func shareWithActivitySheet(text: String, image: UIImage? = nil) async {
        // Prevent multiple presentations
        guard !isPresenting else { return }
        isPresenting = true
        
        defer { isPresenting = false }
        
        // Create activity items
        var items: [Any] = []
        
        // Add the text with hashtags
        let tweetText = "\(text)\n\n#Accessibility #AltText #InclusiveDesign"
        items.append(tweetText)
        
        // Add the image if provided
        if let image = image {
            items.append(image)
        }
        
        // Find the topmost view controller using modern approach
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.keyWindow ?? windowScene.windows.first else {
            return
        }
        
        let presenter = window.rootViewController?.topmostPresentedViewController ?? window.rootViewController
        
        guard let presenter = presenter else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configure for iPad using modern popover configuration
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX, 
                y: presenter.view.bounds.midY, 
                width: 0, 
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        // Use continuation for completion handling
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            activityViewController.completionWithItemsHandler = { _, _, _, _ in
                continuation.resume()
            }
            
            presenter.present(activityViewController, animated: true)
        }
    }
    
    /// Creates a Twitter intent URL for web sharing
    func createTwitterIntentURL(text: String, url: String? = nil) -> URL? {
        var components = URLComponents(string: "https://twitter.com/intent/tweet")
        var queryItems: [URLQueryItem] = []
        
        // Add text parameter
        queryItems.append(URLQueryItem(name: "text", value: text))
        
        // Add URL parameter if provided
        if let url = url {
            queryItems.append(URLQueryItem(name: "url", value: url))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    var topmostPresentedViewController: UIViewController {
        var topViewController = self
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}
