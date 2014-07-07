# -*- encoding : utf-8 -*-
class ReestablecerContrasena < ActionMailer::Base
  default :from => "info@info.com"
  def correo(correo)
    @usuario=Usuario.where("email = ?", correo).first
    @clave = @usuario.clave
    mail(:to=>correo,:subject=>"Contrasena nueva")
  end
end
