# ecommercementorship

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run the web app with the eShop API

The API does not currently allow browser CORS requests. For local web runs,
build the app and serve it through the loopback proxy, which forwards `/api`
requests to the eShop API from the same origin:

```sh
flutter build web --release
python3 tool/serve_web.py
```

Then open the local URL printed by the server. Native iOS and Android builds
continue to connect directly to the API.
