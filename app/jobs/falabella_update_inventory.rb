require 'openssl'
require 'date'
require 'net/http'
require 'uri'

class FalabellaUpdateInventory
  attr_reader :errors

  def initialize
    @errors = []
  end

  def authenticate
    api_key = '23233cbaa2eaf47875047922f73d506aac5f84e8'
    parameters = {
      'UserID' => 'contacto@simplyb.cl',
      'Format' => 'XML',
    }

    # Añadir acción a los parámetros
    parameters['Action'] = 'GetProducts'

    # Añadir versión de la API
    parameters['Version'] = '1.0'

    # Obtener la hora actual formateada como ISO8601
    now = DateTime.now
    parameters['Timestamp'] = now.strftime('%Y-%m-%dT%H:%M:%S%:z')

    # Generar la firma y añadirla a los parámetros
    parameters['Signature'] = generate_signature(api_key, parameters)

    make_falabella_request(parameters)
  end

  def search_products(seller_sku)
    parameters = {
      'UserID' => 'contacto@simplyb.cl',
      'Format' => 'XML',
      'Action' => 'GetProducts',
      'Version' => '1.0',
      'Timestamp' => DateTime.now.strftime('%Y-%m-%dT%H:%M:%S%:z'),
      'Signature' => '',
      'Filter' => 'Sellers',
      'Limit' => 1000,
      'GlobalIdentifier' => 0,
    }
  
    # Generar la firma y añadirla a los parámetros
    parameters['Signature'] = generate_signature('23233cbaa2eaf47875047922f73d506aac5f84e8', parameters)
  
    response = make_falabella_request(parameters)
  
    # Filtrar la respuesta para obtener solo el SellerSku deseado
    desired_product = filter_product_by_sku(response, seller_sku)
    puts desired_product
  end
  
  def filter_product_by_sku(response, seller_sku)
    # Analizar la respuesta XML
    xml_response = Nokogiri::XML(response)
    
    # Encontrar el elemento que contiene el SellerSku deseado
    product_element = xml_response.at("//Product[SellerSku='#{seller_sku}']")
    
    if product_element
      # Devolver el XML del producto encontrado
      product_element.to_xml
    else
      # Si no se encuentra el producto, imprimir un mensaje
      puts "El producto con SellerSku '#{seller_sku}' no fue encontrado."
      nil
    end
  end
  

  private

  def generate_signature(api_signature, parameters)
    # Ordenar parámetros por nombre
    sorted_parameters = parameters.sort.to_h
    # URL encode de los parámetros ordenados
    encoded_parameters = sorted_parameters.map { |name, value| "#{URI.encode_www_form_component(name)}=#{URI.encode_www_form_component(value)}" }
    # Concatenar parámetros codificados en URL
    concatenated = encoded_parameters.join('&')
    # Generar firma HMAC-SHA256
    signature = OpenSSL::HMAC.hexdigest('sha256', api_signature, concatenated)

    puts "Signature: #{signature}"
    URI.encode_www_form_component(signature)
  end

  def make_falabella_request(parameters)
    # Construir la URL de la solicitud
    url = URI.parse('https://sellercenter-api.falabella.com/')
    url.query = URI.encode_www_form(parameters)

    puts "Request URL: #{url}"

    # Realizar la solicitud GET
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Accept'] = 'application/json'

    # Imprimir detalles de la solicitud
    puts "Request Headers: #{request.to_hash.inspect}"

    # Realizar la solicitud y obtener la respuesta
    response = http.request(request)

    # Imprimir detalles de la respuesta
    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"

    # Devolver la respuesta
    response.body
  end
end

# Ejemplo de uso
inventory_updater = FalabellaUpdateInventory.new
inventory_updater.authenticate
# Reemplaza 'SB022' con el SellerSku que estás buscando
inventory_updater.search_products('SB022')




