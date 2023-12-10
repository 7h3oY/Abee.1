
require_relative '../jobs/product_manager_job'

class FalabellaShipping
  def self.perform_shipping
    products_abee = [
      {
        'user_id' => 'contacto@simplyb.cl',
        'token' => '23233cbaa2eaf47875047922f73d506aac5f84e8',
        'products' => [
          { 'skuSeller' => 'SB022', 'quantity' => 2 },
        ]
      },
    ]
    puts "Enviando la lista para el envio..."
    ProductManagerJob.perform_async(products_abee)
    puts "lista enviada"
  end
end
FalabellaShipping.perform_shipping

