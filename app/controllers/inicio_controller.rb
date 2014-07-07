# -*- encoding : utf-8 -*-
class InicioController < ApplicationController
  def index
    if params[:referer].present?
      @referer = params[:referer]
    end
  	if session[:usuario]
          if params[:referer].present?
              redirect_to :action => "index" , :controller => params[:referer]
              return
          else
              redirect_to :action => "bienvenida" , :controller => "principal"
              return
          end
      end
  end

  def validar
    begin
      
      reset_session #Limpia la session
    rescue Exception => e
      
    end
    em =params[:usuarioEmail]
    cl =params[:usuarioClave]
    if usr=Usuario.autenticar(em,cl)      
      session[:usuario]=usr #guardo en la session
      bitacora "El usuario #{usr.descripcion} inicio sesión"
    	session[:rol]=usr.rol
        if params[:referer].present?
	    redirect_to :action => "index" , :controller => params[:referer]
        return # No puede retornar un redirect
        else
          redirect_to :action => "bienvenida" , :controller => "principal"
          return # No puede retornar un redirect
        end
	    
    else
      bitacora "Intento fallido de inicio de sesión con correo: #{em} y clave: #{cl}"
      flash[:error]="Email o Clave Incorrecta"
      redirect_to :action => "index" 
      return #No puede retornar un redirect
    end
  end

  def recordar_contrasena
    bitacora "recordar_contrasena"
    unless params[:usuario_email] 
      flash[:error]="Indique email"
      bitacora "No se indicó el email"
      redirect_to :action => "olvido_contrasena"
      return
    end
     
    email =params[:usuario_email]
    usuario=Usuario.where(:email => email).first

    unless usuario
      bitacora "Intento fallido de recuperación de clave"
      flash[:error2]="Email no encontrado"
      redirect_to :action => "olvido_contrasena"
      return
    end
    usuario.clave=Digest::MD5.hexdigest("#{usuario.email}#{Time.now}")[0..6]
    usuario.save   
    ReestablecerContrasena.correo(email)  
    bitacora "Se envió un correo al usuario #{usuario.nombre} de recuperación de la contraseña"
    flash[:exito]="Se envió una contraseña nueva al correo"
    redirect_to :action =>"index"
    return
  end


end
