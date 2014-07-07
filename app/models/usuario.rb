# -*- encoding : utf-8 -*-
class Usuario < ActiveRecord::Base
	self.table_name = "usuarios"
	has_one :superadmin , :foreign_key => :email
	validates :nombre , :email ,:clave,:presence => true
	validates :nombre , :length => {:minimum => 3}
	validates :email,:email=>true
	validates :email,:uniqueness=>true
	

	def nombre_completo
	  #return nombres + " " + apellidos  PUEDE SER HACKEADO
	  "#{nombre}" #string interpolado(php)
	end
	
	def descripcion
	  "#{email}-#{nombre}"
	end

	def self.getUsuarios
		Usuario.find(:all)
	end
	def self.buscar_usuario(email)
			Usuario.where(:email =>email).first
	end
	
	def self.buscar_informacion(email)
			Usuario.where(:email =>email).first.descripcion
	end
	#metodo a distancia/estatico
	#where retorna un arreglo
	def  self.autenticar(email,clave)
	  # Usuario.where(:cedula => cedula, :clave => clave).first 	
	  # Usuario.where(["cedula = ? AND clave=MD5(?)",cedula,clave]).first
	  # version ruby
   	clave_digest=Digest::MD5.hexdigest(clave)
 		Usuario.where(:email => email, :clave => clave_digest).first 		  

	end
	
	
	def rol
	  return "Superadmin"
	end

	def self.informacion(em)
		Usuario.where(:email => em).first
	end

	
end
