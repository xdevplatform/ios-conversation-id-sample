# Thread reader sample

This sample project illustrated how to create a thread reader experience for iOS. The project uses the Twitter API v2 [recent search](https://developer.twitter.com/en/docs/twitter-api/tweets/recent-search) and [Tweet lookup](https://developer.twitter.com/en/docs/twitter-api/tweets/lookup) endpoints.

## Configuration

The project is configured to use the Twitter API v2 recent search endpoint. You will need the following

1. Have a Twitter developer account. If you don't have one, you can [apply for access](https://developer.twitter.com/apply).
2. Make sure you have an app connected to a Twitter API v2 project. If you don't have a project, follow the [instructions on our developer documentation](https://developer.twitter.com/en/docs/projects/overview).
3. Get a Bearer token for your app. You should have stored this value safely when you created your app. If you can't find your Bearer token, look in Keys and tokens section in the [developer portal](https://developer.twitter.com/portal).
4. In Xcode, open TwitterSettings.plist under the Threadshare group. Locate the `bearerToken` entry and replace the default value with your Bearer token.
5. Build the project.
