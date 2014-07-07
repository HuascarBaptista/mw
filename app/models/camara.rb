# -*- encoding : utf-8 -*-
class Camara < ActiveRecord::Base
  self.table_name = "camaras"
	validates :ip,:uniqueness=>true,:presence => { :message =>"Ip repetida, por favor selecciona otra." }
            #:format => { :with => Resolv::IPv4::Regex, :message => "No es una dirección IPv4 válida"}
	belongs_to :modelos , :class_name => "Modelo", :foreign_key => :modelo_id
  # attr_accessible :title, :body

  def self.ipToModel(ip)
  	camara = Camara.where(:ip => ip).first
  	if camara
  		modelo = Modelo.where(:id => camara.modelo_id).first
  	else
  		return 
  	end
  	return modelo
  end
  def self.ipToCamara(ip)
  	camara = Camara.where(:ip => ip).first
  end
end

