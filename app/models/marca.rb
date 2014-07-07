# -*- encoding : utf-8 -*-
class Marca < ActiveRecord::Base
  self.table_name = "marcas"
	validates :nombre, :uniqueness=> true
end

