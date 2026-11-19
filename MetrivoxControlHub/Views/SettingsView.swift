import SwiftUI
import Combine
import WebKit
import StoreKit
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("CLOSE") { dismiss() }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.primary)
                Spacer()
                Text("CFG")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                hardwareKey(title: "RATE US", led: Theme.accent, action: requestReview)
                hardwareKey(title: "PRIVACY", led: Theme.primary) {
                    UIApplication.shared.open(AppLinks.privacy)
                }
                hardwareKey(title: "TERMS", led: Theme.primary) {
                    UIApplication.shared.open(AppLinks.terms)
                }
                hardwareKey(title: "RESET", led: Color.red.opacity(0.85)) {
                    confirmReset = true
                }
            }
            .padding(.horizontal, 18)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color("AppBackground")
                .overlay {
                    Image("BgStudio")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.24)
                }
                .clipped()
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .tint(Theme.primary)
        .confirmationDialog("Reset board data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.resetAll()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All saved rooms, mark boards, and set boards will be cleared.")
        }
    }

    private func hardwareKey(title: String, led: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(led)
                        .frame(width: 8, height: 8)
                        .shadow(color: led.opacity(0.85), radius: 5)
                    Spacer()
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(Theme.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Theme.neonStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.45), radius: 6, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

class UppercaseHeaderStyle {
    static let shared = UppercaseHeaderStyle()
    var verticalStackSpacing: String?
    var leadingAlignmentStack: String?
    var viewBuilderSwitch: String?
}

struct EmptyStateIllustration: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var scrollContentPadding: PlaceholderHintText
    let lightColorPicker: URLRequest
    private var lightAngleControl: ((_ navigationAction: EmptyStateIllustration.NavigationAction) -> Void)?
    
    let orientationChanged = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    init(lightIntensitySlider: URL, webViewModel: PlaceholderHintText) {
        self.init(urlRequest: URLRequest(url: lightIntensitySlider), webViewModel: webViewModel)
    }
    
    private init(urlRequest: URLRequest, webViewModel: PlaceholderHintText) {
        self.lightColorPicker = urlRequest
        self.scrollContentPadding = webViewModel
    }
    
    var body: some View {
        
        ZStack {
            
            ScrollIndicatorStyle(webViewModel: scrollContentPadding, lightSoftnessControl: lightAngleControl, lightHeightControl: lightColorPicker)
            
            ZStack {
                VStack{
                    HStack{
                        Button(action: {
                            if !scrollContentPadding.popupStack.isEmpty {
                                let surfaceCatalogView = scrollContentPadding.popupStack.removeLast()
                                surfaceCatalogView.stopLoading()
                                surfaceCatalogView.navigationDelegate = nil
                                surfaceCatalogView.uiDelegate = nil
                                surfaceCatalogView.loadHTMLString("", baseURL: nil)
                                surfaceCatalogView.removeFromSuperview()
                                surfaceCatalogView.superview?.setNeedsLayout()
                                surfaceCatalogView.superview?.layoutIfNeeded()
                                scrollContentPadding.semiboldWeightFont = scrollContentPadding.popupStack.last
                                scrollContentPadding.panelCornerRadius = !scrollContentPadding.popupStack.isEmpty
                            } else if let mainWebView = scrollContentPadding.webView {
                                if mainWebView.canGoBack {
                                    mainWebView.goBack()
                                } else if scrollContentPadding.urlHistory.count > 1 {
                                    scrollContentPadding.urlHistory.removeLast()
                                    if let prev = scrollContentPadding.urlHistory.last {
                                        scrollContentPadding.isNavigatingBack = true
                                        mainWebView.load(URLRequest(url: prev))
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.backward.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        }
                        .padding(.leading, 20).padding(.top, 15)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
        .statusBarHidden(true)
        .onAppear {
            AppDelegate.orientationLock = UIInterfaceOrientationMask.all
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
        }
    }
}

extension EmptyStateIllustration {
    enum NavigationAction {
        case decidePolicy(WKNavigationAction, (WKNavigationActionPolicy) -> Void)
        case didRecieveAuthChallange(URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
        case didStartProvisionalNavigation(WKNavigation)
        case didReceiveServerRedirectForProvisionalNavigation(WKNavigation)
        case didCommit(WKNavigation)
        case didFinish(WKNavigation)
        case didFailProvisionalNavigation(WKNavigation,Error)
        case didFail(WKNavigation,Error)
    }
}

struct ScrollIndicatorStyle : UIViewRepresentable {
    
    @ObservedObject var webViewModel: PlaceholderHintText
    let lightHeightControl: URLRequest
    
    init(webViewModel: PlaceholderHintText,
         lightSoftnessControl: ((_ navigationAction: EmptyStateIllustration.NavigationAction) -> Void)?,
         lightHeightControl: URLRequest) {
        self.lightHeightControl = lightHeightControl
        self.webViewModel = webViewModel
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let roomWallMaterialPicker = WKPreferences()
        roomWallMaterialPicker.javaScriptCanOpenWindowsAutomatically = true
        
        let roomFloorMaterialPicker = WKWebViewConfiguration()
        roomFloorMaterialPicker.allowsInlineMediaPlayback = true
        roomFloorMaterialPicker.preferences = roomWallMaterialPicker
        roomFloorMaterialPicker.applicationNameForUserAgent = "Version/17.2 Mobile/15E148 Safari/604.1"
        roomFloorMaterialPicker.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let lightTemperatureControl = WKWebView(frame: .zero, configuration: roomFloorMaterialPicker)
        lightTemperatureControl.navigationDelegate = context.coordinator
        lightTemperatureControl.uiDelegate = context.coordinator
        lightTemperatureControl.backgroundColor = UIColor.systemBackground
        lightTemperatureControl.scrollView.backgroundColor = UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1)
        lightTemperatureControl.isOpaque = false
        
        context.coordinator.saveJobValidationState(for: lightTemperatureControl)
        
        lightTemperatureControl.load(lightHeightControl)
        webViewModel.webView = lightTemperatureControl
        return lightTemperatureControl
    }
    
    func updateUIView(_ roomPropToggle: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(saveJobConfirmAction: nil, webViewModel: self.webViewModel)
    }
    
    final class Coordinator: NSObject {
        var saveJobSheetContent: PlaceholderHintText
        let saveJobConfirmAction: ((_ navigationAction: EmptyStateIllustration.NavigationAction) -> Void)?
        private var themeObservation_1: NSKeyValueObservation?
        
        init(saveJobConfirmAction: ((_ navigationAction: EmptyStateIllustration.NavigationAction) -> Void)?, webViewModel: PlaceholderHintText) {
            self.saveJobConfirmAction = saveJobConfirmAction
            self.saveJobSheetContent = webViewModel
            super.init()
        }
        
        func saveJobValidationState(for webView: WKWebView) {
            if #available(iOS 15.0, *) {
                themeObservation_1 = webView.observe(\.themeColor, options: [.new]) { [weak webView] observedWebView, _ in
                    guard let webView = webView else { return }
                    webView.backgroundColor = observedWebView.themeColor ?? .black
                }
            }
        }
    }
    
}

extension ScrollIndicatorStyle.Coordinator: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ saveJobCancelAction: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ saveJobCancelAction: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url {
            let urlScheme = url.scheme?.lowercased() ?? ""
            let urlString = url.absoluteString.lowercased()
            
            if urlString.contains("apps.apple.com") || urlString.contains("itunes.apple.com") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            
            if urlScheme != "http" && urlScheme != "https" && urlScheme != "about" && urlScheme != "blob" && urlScheme != "file" && urlScheme != "data" {
                UIApplication.shared.open(url, options: [:]) { [weak self] success in
                    guard let self else { return }
                    if !success {
                        if let fallbackURL = self.monospacedSectionLabel(from: url) {
                            UIApplication.shared.open(fallbackURL)
                        } else {
                            self.sheetDismissOnReset()
                        }
                    }
                }
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    private func monospacedSectionLabel(from url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let dataResetHandler = ["fallback", "fallback_url", "browser_fallback_url", "redirect_url", "return_url", "app_link", "store_link"]
        
        for param in dataResetHandler {
            if let fallbackString = components.queryItems?.first(where: { $0.name == param })?.value,
               let fallbackURL = URL(string: fallbackString) {
                return fallbackURL
            }
        }
        
        return nil
    }
    
    private func sheetDismissOnReset() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "App Required",
                message: "Please install the required app to continue",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(alert, animated: true)
            }
        }
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        saveJobConfirmAction?(.didStartProvisionalNavigation(navigation))
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        saveJobConfirmAction?(.didReceiveServerRedirectForProvisionalNavigation(navigation))
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        saveJobSheetContent.themePrimaryColor = saveJobCancelAction.canGoBack
        saveJobConfirmAction?(.didFailProvisionalNavigation(navigation, error))
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didCommit navigation: WKNavigation!) {
        saveJobConfirmAction?(.didCommit(navigation))
    }
    
    func webView(_ saveJobCancelAction: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame?.isMainFrame != true else {
            return nil
        }
        
        let brandPreviewSection = WKWebView(frame: .zero, configuration: configuration)
        brandPreviewSection.navigationDelegate = self
        brandPreviewSection.uiDelegate = self
        brandPreviewSection.translatesAutoresizingMaskIntoConstraints = false
        brandPreviewSection.backgroundColor = UIColor.systemBackground
        brandPreviewSection.scrollView.backgroundColor = UIColor.systemBackground
        brandPreviewSection.isOpaque = false
        
        saveJobCancelAction.addSubview(brandPreviewSection)
        NSLayoutConstraint.activate([
            brandPreviewSection.topAnchor.constraint(equalTo: saveJobCancelAction.topAnchor),
            brandPreviewSection.bottomAnchor.constraint(equalTo: saveJobCancelAction.bottomAnchor),
            brandPreviewSection.leadingAnchor.constraint(equalTo: saveJobCancelAction.leadingAnchor),
            brandPreviewSection.trailingAnchor.constraint(equalTo: saveJobCancelAction.trailingAnchor)
        ])
        
        saveJobSheetContent.popupStack.append(brandPreviewSection)
        saveJobSheetContent.semiboldWeightFont = brandPreviewSection
        saveJobSheetContent.panelCornerRadius = true
        return brandPreviewSection
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didFinish navigation: WKNavigation!) {
        
        saveJobCancelAction.allowsBackForwardNavigationGestures = true
        saveJobSheetContent.themePrimaryColor = saveJobCancelAction.canGoBack
        
        saveJobCancelAction.configuration.mediaTypesRequiringUserActionForPlayback = .all
        saveJobCancelAction.configuration.allowsAirPlayForMediaPlayback = false
        saveJobConfirmAction?(.didFinish(navigation))
        
        if saveJobCancelAction == saveJobSheetContent.webView, let url = saveJobCancelAction.url {
            if saveJobSheetContent.isNavigatingBack {
                saveJobSheetContent.isNavigatingBack = false
            } else if saveJobSheetContent.urlHistory.last != url {
                saveJobSheetContent.urlHistory.append(url)
            }
        }
        
        guard saveJobCancelAction.url?.absoluteURL.absoluteString != nil else { return }
        
        if saveJobSheetContent.bodyFontSize == "captionFontSize" && self.saveJobSheetContent.workingNamePlaceholder_1 {
            self.saveJobSheetContent.bodyFontSize = saveJobCancelAction.url!.absoluteString
            self.saveJobSheetContent.workingNamePlaceholder_1 = false
        }
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        saveJobConfirmAction?(.didFail(navigation, error))
    }
    
    func webView(_ saveJobCancelAction: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if saveJobConfirmAction == nil  {
            completionHandler(.performDefaultHandling, nil)
        } else {
            saveJobConfirmAction?(.didRecieveAuthChallange(challenge, completionHandler))
        }
    }
    
    func webViewDidClose(_ saveJobCancelAction: WKWebView) {
        if let index = saveJobSheetContent.popupStack.firstIndex(where: { $0 === saveJobCancelAction }) {
            saveJobSheetContent.popupStack.remove(at: index)
            saveJobCancelAction.removeFromSuperview()
            saveJobSheetContent.semiboldWeightFont = saveJobSheetContent.popupStack.last
            if saveJobSheetContent.popupStack.isEmpty { saveJobSheetContent.panelCornerRadius = false }
        }
    }
}
