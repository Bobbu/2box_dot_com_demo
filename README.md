# 2box_dot_com_demo

A mini app intended to illustrate incorporating Box.com into a Flutter app -- using the Oauth2 REST API from Box.com.

## Getting Started

You will want to create an account and an app at developer.box.com. The app should be a "custom app" intended for individuals and potentially affording any/all possible scopes.

To employ in Flutter, we relied on a custom url sceheme that did not have http or https at the front. Instead, our redirect URL looks like hrp01://redirect.

## Key Dependencies

### flutter_web_auth

This is how we implement the Oauth2 Authorization Code flow. We also employ a "custom URL scheme" to support our redirect URI.

For more, visit:
https://pub.dev/packages/flutter_web_auth


### flutter_secure_storage

This is how we store access and refresh tokens locally and securelly.

for more, visit:
https://pub.dev/packages/flutter_secure_storage

See the publspec.yaml file for other less crucial dependencies.

## API Keys and Other Secrets

We use a git-ignored secrets.dart in lib/auth/secrets.dart to store the API client ID and secret ID.
Anyone employing this will want to create their own lib/auth/secrets.dart. 

This way of keeping needed API keys secret was based off a post found on Medium.com:
https://medium.com/podiihq/keeping-secret-keys-out-of-version-control-in-flutter-bcd2b1eb9c1b

Any ideas on how to improve this? I am all ears.