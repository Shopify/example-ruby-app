# Example Shopify app in Ruby

This is an example Shopify application written in [Sinatra](https://github.com/sinatra/sinatra) solely for the purposes of introducing new developers to the Shopify API.

## Credentials

This example uses a `.env` file to store the application credentials. After cloning the repository, you'll need to create a file named `.env` in the same folder. The contents of the file should be as follows:
```
API_KEY=YOUR_API_KEY
API_SECRET=YOUR_SECRET_KEY
```

where `YOUR_API_KEY` and `YOUR_SECRET_KEY` are the values of your application's API key and secret key respectively.

To retrieve your API credentials, sign up for a [Shopify Partners account](https://app.shopify.com/services/partners/auth/login) and [follow this guide](/api/introduction/getting-started).

## Running the app

1. Create the `.env` file as described above.
2. `bundle install` to obtain all of the necessary dependencies
3. `ruby app.rb` to run the example application.
