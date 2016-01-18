# shopify-ruby-giftbasket

This is an example Shopify application written in Sinatra solely for the purposes of introducing new developers to the Shopify API.

This example uses a `.env` file to store the application credentials. After cloning the repository, you'll need to create a file named `.env` in the same folder. The contents of the file should be as follows:
```
API_KEY=YOUR_API_KEY
API_SECRET=YOUR_SECRET_KEY
```

where API_KEY and API_KEY are the values of your application's API key and secret key respectively.

To get started with this example:

1. Create the `.env` file as described above.
2. `bundle install` to obtain all of the necessary dependencies
3. `ruby app.rb` to run the example application.
