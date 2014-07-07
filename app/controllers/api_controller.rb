# -*- encoding : utf-8 -*-
require 'net/ftp'

class FtpController < ApplicationController
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
  layout 'autenticado.html.haml'
  def index
  end
  def prueba
    ip = params[:ip]
    modelo = Camara.ipToModel(ipCamara)
    camara = Camara.ipToCamara(ipCamara)
    getFile(modelo.objeto)
    script = modelo.objeto.constantize
    c = script.new(camara.ip, camara.usuario, camara.contrasena)

    begin
      
      
      respuesta2 = c.setFtp(ftp.host,ftp.puerto,ftp.usuario,ftp.clave,ruta)
    rescue Exception => e
      flash[:error]= "#{e}"
    end
    flash[:exito]= "#{respuesta2}"
    redirect_to :action=>"index"
    return

  end
  
  def getFile(nombre)

    Dir[File.dirname(__FILE__) +"/../models/controladores/#{nombre}.rb"].each do |file| 
      begin
        Rails.logger.debug "EL ARCHIVO #{file}"
        require file
      rescue Exception => err
        Rails.logger.debug "EL EERROOR ARCHIVO #{err}"
      end
    end
  end
  
end
