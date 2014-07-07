# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  protect_from_forgery
  def bitacora(descripcion)
    b=Bitacora.new
    b.descripcion=descripcion
    b.usuario=session[:usuario].nombre_completo if session[:usuario]
    b.fecha_hora=Time.now #Hora del servidor
    b.ip=request.remote_ip #IP accediendo 
    b.save    
  end
    
  def verificar_autenticado
    unless session[:usuario] #else if,tiene quer ser falso
      bitacora "Intento de accceso sin autenticación"
      flash[:mensaje]="Debe autenticarse"
      redirect_to :action => "index" , :controller => "inicio"
      return false
    end
  end

  def validar 
    @ip = params[:ip]
    unless @ip
      @ip = request.remote_ip
    end
    
    if params[:serverId].present?  && params[:serverKey].present? && params[:script].present?
      #autenticamos al usuario
      @server_id = params[:serverId]
      @server_key = params[:serverKey]
      @script = params[:script]

      autenticacion = Autenticacion.where(:server_id=>@server_id,:server_key=>@server_key).first
      unless autenticacion
        msg = { :status => "error", :message => "error de autenticacion"}
        render :json => msg
        return
      end
      Rails.logger.debug "--- AUTENTICACION ID #{autenticacion.id}"
      si = ScriptImagen.where(:autenticacion_id => autenticacion.id).first
      unless si.present?
        Rails.logger.debug "--- AGREGO SCRIPT "
        si = ScriptImagen.new
        si.autenticacion_id = autenticacion.id
        si.script = @script
      end
      si.script = @script
      si.save
      autenticacion.autenticado = true
      autenticacion.save
    else

      #verificamos la ip, si esta guardada no le damos NADA sino le damos server_id, server_key
      autenticacion = Autenticacion.where(:ip=>@ip).first

      if autenticacion.present?
        if autenticacion.autenticado == false
          msg = { :status => "success", :server_id => @server_id, :server_key => @server_key}
          render :json => msg
          return
        end
      end

      Rails.logger.debug "Aqui UP---- #{autenticacion}"
      if autenticacion
        msg = { :status => "error", :message => "error de autenticacion"}
        render :json => msg
        return
      else  
      #Le damos un server_id server_key y guardamos la ip
        inicio = rand(0..5)
          fin = rand(inicio+1..12)
        @server_id = Digest::MD5.hexdigest("huascarMilagros#{Time.current()}")[inicio..fin]
        inicio = rand(0..5)
          fin = rand(inicio+1..12)
        @server_key = Digest::MD5.hexdigest("huascarMilagros#{Time.current()}")[inicio..fin]
        autenticacion = Autenticacion.new
        autenticacion.server_id = @server_id
        autenticacion.server_key = @server_key
        autenticacion.ip = @ip
        autenticacion.save
      end
    end
    reset_session #Limpia la session
    session[:id_autenticacion] = autenticacion.id
  end


end
