# -*- encoding : utf-8 -*-
class ScriptImagen < ActiveRecord::Base
        self.table_name = "script_imagen"
	validates :autenticacion_id,:uniqueness=>true
	belongs_to :autenticacion ,:foreign_key => :autenticacion_id
  # attr_accessible :title, :body
end

