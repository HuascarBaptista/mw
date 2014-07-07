# -*- encoding : utf-8 -*-
class TemporalController < ApplicationController
	before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
	layout 'autenticado.html.haml'
	def index
		@tengo = leer

	end
	def editar_valor
		if params[:valor]
			valor = params[:valor].to_i
			if valor <= 0
				valor = 1
				flash[:error]="La duración en días debe ser mayor a 1."
			end		
			escribir(valor)
		else
			flash[:exito]="El tiempo se mantuvo"
			redirect_to :action => "index"
			return
		end  
		bitacora "El usuario #{session[:usuario].descripcion} modificó los días de duración de los temporales a #{valor}"
		flash[:exito]="Tiempo modificado con éxito"
		redirect_to :action => "index"
		return
	end
	def existe
		return File.exist?("temporal.txt")
	end
	def leer
		if existe
			logger.debug "#{File.read("temporal.txt")}"
			return File.read("temporal.txt")
		else
			escribir("15")
			return File.read("temporal.txt")
		end
	end  
 
	def escribir(valor)

		File.open('temporal.txt', 'w') do |f2|  
			f2.write valor
		end
	end
end
