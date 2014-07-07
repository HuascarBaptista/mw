# -*- encoding : utf-8 -*-
class Autenticacion < ActiveRecord::Base
  self.table_name = "autenticacion"
	validates :ip,:uniqueness=>true
	validates :server_id, uniqueness: { scope: :server_key, message: "Debe ser unico el server_id y server_key" }
  # attr_accessible :title, :body
end

