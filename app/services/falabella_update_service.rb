require 'net/http'
require 'builder'
require_relative 'falabella_signature_service'

class FalabellaUpdateService
  attr_reader :errors

  def initialize(products_update)
    @products_update = products_update

    @signature_service = FalabellaSignatureService.new

    @errors = []
  end

  def create_all(products_update)

    puts "Contenido de la lista en create all: #{products_update}"

    products_update.each do |product_update|

      user_id = product_update['user_id']
      token = product_update['token']
      signature = product_update['signature_user']
      products = product_update['products']

      puts "UserID: #{user_id}"

      puts "Signature en create all: #{signature}"

      puts "Products: #{products}"

      xml_request_body = build_xml_request(products_update)
      response = connect_falabella('https://sellercenter-api.falabella.com/?Action=ProductUpdate', xml_request_body, user_id, signature)
      
      if response.code.to_i == 200
        puts "Inventory updated successfully for UserID: #{user_id}"
        puts "API Response: #{response.body}"
        save_response(response.body, response.code.to_i, products_update, 'success')

      else
        @errors << "Failed to update inventory for UserID #{user_id}. Status code: #{response.code}, Response: #{response.body}"
        puts "Failed to update inventory for UserID #{user_id}. Response: #{response.body}"        
        save_response(response.body, response.code.to_i, products_update, 'Pending')

      end

    end

  end

  private

  def build_xml_request(products_update)
    puts "Products Update: #{products_update.inspect}"  
    xml_builder = Builder::XmlMarkup.new(indent: 2)
    xml_builder.instruct! :xml, version: '1.0', encoding: 'UTF-8'
    xml_builder.Request do
      products_update.each do |product_update|
        user_id = product_update['user_id']
        products = product_update['products']        
        puts "UserID: #{user_id}"
        puts "Products: #{products.inspect}"  
        xml_builder.Product do
          xml_builder.SellerSku products['skuSeller']
          xml_builder.BusinessUnits do
            xml_builder.BusinessUnit do
              xml_builder.OperatorCode 'facl'
              xml_builder.Stock products['quantity']
            end
          end
        end
      end
    end
    puts "XML Request: #{xml_builder.target!}" 

    xml_builder.target!
  end
  
  def save_response(body, status_code, products_update, status)
    ApiResponse.create( #nombre de la clase del modelo que guarda en la BD los datos de la response
      body: body,
      status_code: status_code,
      user_id: user_id,
      products_update: products_update.to_json,
      status: status
    )
  end
  

  def connect_falabella(url, request_body, user_id, signature)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    puts "Signature en connect_fallabela: #{signature}"
    now = DateTime.now   
    parameters = {
      'Action' => 'ProductUpdate',
      'Format' => 'XML',
      'Version' => '1.0',
      'Timestamp' => now.strftime('%Y-%m-%dT%H:%M:%S%:z'),
      'UserID' => user_id,
      'Signature' => signature
    }

    uri.query = URI.encode_www_form(parameters)
    request = Net::HTTP::Post.new(uri)
    request['Accept'] = 'application/json'
    request['Content-Type'] = 'application/xml'
    request.body = request_body
    http.request(request)
  end
end




