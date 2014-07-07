# -*- encoding : utf-8 -*-
class Modelo < ActiveRecord::Base
  self.table_name = "modelos"
	validates :marca_id, uniqueness: { scope: :nombre, message: "Debe ser unico el marca_id y nombre" }
	belongs_to :marca ,:class_name => "Marca", :foreign_key => :marca_id
  # attr_accessible :title, :body
end
