require 'shopify_api'
require 'sinatra'
require 'httparty'
require 'dotenv'


class GiftBasket < Sinatra::Base
  attr_reader :key,:secret,:tokens

  def initialize
    Dotenv.load
    @key = ENV['API_KEY']
    @secret = ENV['API_SECRET']
    @app_url = "jamied.ngrok.io"
    @tokens = {}
    super
  end

  get '/giftbasket/install' do
    shop = request.params['shop']
    scopes = "read_orders,read_products,write_products"

    # construct the installation URL and redirect the merchant
    install_url = "http://#{shop}/admin/oauth/authorize?client_id=#{@key}"\
                "&scope=#{scopes}&redirect_uri=https://#{@app_url}/giftbasket/auth"

    # redirect to the install_url
    redirect install_url
  end

  get '/giftbasket/auth' do
    # extract shop data from request parameters
    shop = request.params['shop']
    code = request.params['code']
    hmac = request.params['hmac']

    # perform hmac validation to determine if the request is coming from Shopify
    validate_hmac(hmac,request)

    # if no access token for this particular shop exist,
    # POST the OAuth request and receive the token in the response
    get_shop_access_token(shop,key,secret,code)

    # subscribe to the order/create webhook
    create_order_webhook

    # redirect to the bulk edit URL if there is a token and an activated session
    redirect bulk_edit_url
  end

  post '/giftbasket/webhook/order_create' do
    # inspect hmac value in header and verify webhook
    hmac = request.env['HTTP_X_SHOPIFY_HMAC_SHA256']

    request.body.rewind
    data = request.body.read
    webhook_ok = verify_webhook(hmac, data)

    if webhook_ok
      shop = request.env['HTTP_X_SHOPIFY_SHOP_DOMAIN']
      token = @tokens[shop]

      if not token.nil?
        session = ShopifyAPI::Session.new(shop, token)
        ShopifyAPI::Base.activate_session(session)
      else
        return [403, "You're not authorized to perform this action."]
      end
    else
      return [403, "You're not authorized to perform this action."]
    end

    # parse the request body as JSON data
    json_data = JSON.parse data

    line_items = json_data['line_items']

    line_items.each do |line_item|
      variant_id = line_item['variant_id']

      variant = ShopifyAPI::Variant.find(variant_id)

      variant.metafields.each do |field|
        if field.key == 'ingredients'
          items = field.value.split(',')

          items.each do |item|
            gift_item = ShopifyAPI::Variant.find(item)
            gift_item.inventory_quantity = gift_item.inventory_quantity - 1
            gift_item.save
          end
        end
      end
    end

    return [200, "Webhook notification received successfully."]
  end


  helpers do
    def get_shop_access_token(shop,client_id,client_secret,code)
      if @tokens[shop].nil?
        url = "https://#{shop}/admin/oauth/access_token"

        payload = {
          client_id: client_id,
          client_secret: client_secret,
          code: code}

        response = HTTParty.post(url, body: payload)
        # if the response is successful, obtain the token and store it in a hash
        if response.code == 200
          @tokens[shop] = response['access_token']
        else
          return [500, "Something went wrong."]
        end

        instantiate_session(shop)
      end
    end

    def instantiate_session(shop)
      # now that the token is available, instantiate a session
      session = ShopifyAPI::Session.new(shop, @tokens[shop])
      ShopifyAPI::Base.activate_session(session)
    end

    def validate_hmac(hmac,request)
      h = request.params.reject{|k,_| k == 'hmac' || k == 'signature'}
      query = URI.escape(h.sort.collect{|k,v| "#{k}=#{v}"}.join('&'))
      digest = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @secret, query)

      if not (hmac == digest)
        return [403, "Authentication failed. Digest provided was: #{digest}"]
      end
    end

    def verify_webhook(hmac, data)
      digest = OpenSSL::Digest.new('sha256')
      calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, @secret, data)).strip

      hmac == calculated_hmac
    end

    def bulk_edit_url
      bulk_edit_url = "https://www.shopify.com/admin/bulk"\
                    "?resource_name=ProductVariant"\
                    "&edit=metafields.test.ingredients:string"
      return bulk_edit_url
    end

    def create_order_webhook
      # create webhook for order creation if it doesn't exist
      if not ShopifyAPI::Webhook.find(:all).any?
        webhook = {
          topic: 'orders/create',
          address: "https://#{@app_url}/giftbasket/webhook/order_create",
          format: 'json'}

        ShopifyAPI::Webhook.create(webhook)
      end
    end
  end

end

run GiftBasket.run!
