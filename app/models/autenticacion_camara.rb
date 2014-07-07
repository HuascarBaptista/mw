# -*- encoding : utf-8 -*-
class AutenticacionCamara < ActiveRecord::Base
  self.table_name = "autenticacion_camaras"
	validates :autenticacion_id, uniqueness: { scope: :camara_id, message: "Debe ser unico el autenticacion_id y camara_id" }
	belongs_to :camaras ,:foreign_key => :camara_id
	belongs_to :autenticacion ,:foreign_key => :autenticacion_id
  # attr_accessible :title, :body
end
