# -*- encoding : utf-8 -*-
class AutenticacionController < ApplicationController
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
  layout 'autenticado.html.haml'
  def index
    @clientes_autenticados = Autenticacion.all
    
  end

  def eliminar_cliente
  	id=params[:id]

  	cliente=Autenticacion.where(:id=>id).first

  	logger.debug "-------------------------------------AQUI ID: #{id}"

  	logger.debug "-------------------------------------AQUI clientes_autenticados encontradas: #{cliente}"

  	unless cliente
  		flash[:error]="No se encontró el cliente"
			redirect_to :action => "index"
			return
  	end


  	cliente.delete
		flash[:exito]="Se eliminó el cliente"
		redirect_to :action => "index" 
		return
  	
  end
  

end
