import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set system status bar color to match our app theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.orange,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '94vibes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;
  bool isLoading = true;
  double loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingProgress = progress / 100;
              if (progress > 80) {
                isLoading = false;
              }
            });
            // Early injection during progress - only once if possible
            if (progress > 10) {
              _applyNativeFilters();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              loadingProgress = 0;
            });
            _applyNativeFilters();
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
              loadingProgress = 1.0;
            });
            _applyNativeFilters();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://94vibes.ae/'));
  }

  void _applyNativeFilters() {
    // Advanced CSS to make it look like a native app
    // Optimized CSS injection to prevent layout thrashing and duplication
    controller.runJavaScript("""
      (function() {
        var styleId = 'native-app-styles';
        var style = document.getElementById(styleId);
        if (!style) {
          style = document.createElement('style');
          style.id = styleId;
          document.head.appendChild(style);
        }
        
        style.innerHTML = `
          .footer-wrapper, footer, .bottom-bar { 
            display: none !important; 
          }
          
          /* Hide Scrollbars */
          ::-webkit-scrollbar {
            display: none !important;
          }
          
          /* Disable Text Selection & Long Press for native feel */
          * {
            -webkit-tap-highlight-color: transparent !important;
          }
          
          /* Fix layout for mobile */
          body { 
            padding-top: 0 !important; 
            margin-top: 0 !important; 
            overflow-x: hidden !important;
            width: 100vw !important;
          }
          
          .content-area, main {
            padding-top: 5px !important;
          }
        `;

        // Only inject viewport meta if not already present
        if (!document.querySelector('meta[name="viewport"]')) {
          var meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
          document.head.appendChild(meta);
        }
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await controller.canGoBack()) {
          await controller.goBack();
        } else {
          if (context.mounted) {
            // Optional: You could show a confirmation dialog before exiting
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          title: const Text(
            '94vibes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              if (await controller.canGoBack()) {
                await controller.goBack();
              }
            },
          ),
          centerTitle: true,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
        ),
        body: Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                WebViewWidget(controller: controller),
                if (isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: loadingProgress > 0.1 ? loadingProgress : null,
                      backgroundColor: Colors.white,
                      color: Colors.orange,
                      minHeight: 3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
