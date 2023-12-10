
require 'sucker_punch'
require_relative '../services/falabella_update_service'
require_relative '../services/falabella_signature_service'

class ProductManagerJob
  include SuckerPunch::Job
  
    def perform(products_abee)
      @signature_service = FalabellaSignatureService.new
      @update_products = FalabellaUpdateService.new(products_abee)
      manage_update(products_abee)
    end
  
    private
  
    def manage_update(products_abee)
      products_abee.each do |api_signature|
        user_id = api_signature['user_id']
        token = api_signature['token']
        signature = @signature_service.make_falabella_request('ProductUpdate', {}, user_id, token)
        products_update = build_products_update_array(api_signature['products'], user_id, token, signature)
        puts "Cotenido de la lista uptade: #{products_update}"
        @update_products.create_all(products_update)
        puts "Signature: #{signature}"
      end
    end
  
    def build_products_update_array(products, user_id, token, signature)
      products_update_array = []
  
      products.each do |product|
        products_to_update = {
          'user_id' => user_id,
          'token' => token,
          'signature_user' => signature,
          'products' => product
        }
        products_update_array << products_to_update
      end
  
      puts "Productos a actualizar : #{products_update_array}"
      products_update_array
    end
  end
  




