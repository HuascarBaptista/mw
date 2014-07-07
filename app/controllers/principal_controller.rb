# -*- encoding : utf-8 -*-
class PrincipalController < ApplicationController
  layout 'autenticado.html.haml'
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto

  def bienvenida
    if session[:rol].eql?("Administrador") || session[:rol].eql?("Superadmin")
      @titulo_pagina= ( session[:rol].eql?("Administrador") ? "Administrador" : "Superadmin")
    elsif session[:rol].eql?("Usuario")
      @titulo_pagina= "Menu"     
    end
  end
  def cerrar_sesion
    bitacora "El usuario #{session[:usuario].descripcion} ha cerrado sesión"
    reset_session
    redirect_to :action => "index" , :controller => "inicio"
    return
  end

  def olvido_contrasena
    @titulo_pagina= "Recuperar Contraseña"
  end

end
