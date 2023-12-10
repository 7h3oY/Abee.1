require 'openssl'
require 'date'
require 'net/http'
require 'uri'

class FalabellaSignatureService
  attr_reader :errors

  def initialize()
    @errors = []
  end

  # Método para generar la firma HMAC-SHA256
  def generate_signature(api_signature, parameters)

    sorted_parameters = parameters.sort.to_h

    encoded_parameters = sorted_parameters.map { |name, value| "#{URI.encode_www_form_component(name)}=#{URI.encode_www_form_component(value)}" }
    
    concatenated = encoded_parameters.join('&')

    signature = OpenSSL::HMAC.hexdigest('sha256', api_signature, concatenated)
    
    puts "Signature : #{signature}"

    URI.encode_www_form_component(signature)
  end

  # Método para realizar una solicitud a la API de Falabella
  def make_falabella_request(action, parameters, user_id, token)

    api_signature = token   

    parameters['Action'] = action

    parameters['Version'] = '1.0'

    now = DateTime.now

    parameters['Timestamp'] = now.strftime('%Y-%m-%dT%H:%M:%S%:z')

    parameters['UserID'] = user_id

    parameters['Format'] = 'XML'

    parameters['Signature'] = generate_signature(api_signature, parameters)

    url = URI.parse('https://sellercenter-api.falabella.com/')

    url.query = URI.encode_www_form(parameters)

    response = Net::HTTP.get_response(url)
    puts "URL: #{url}"

    puts "Parametros : #{parameters}"

    puts "API Response: #{response.body}"
    
    parameters['Signature']
  end

end
