# -*- encoding : utf-8 -*-

require "base64"
require "uri"
require "socket"
require "net/http"
require "cgi"

# This is the ruby driver for the Trendnet TV-IP400 or TV-IP400W IP camera. 
# -*- encoding : utf-8 -*-
class Ip2120
  
  UP = 1
  DOWN = -1
  RIGHT = 1
  LEFT = -1
  @auth_id = nil
  @username = nil
  @password = nil
  @deteccion = nil
  # constructor. Username and password are optional. If you don't specify them 
  # then make sure that User Access Control is disabled in the Trendnet configuration
  # interface. 
  def initialize(host, username = nil, passwd = nil,detec = nil)
    @control_url = "http://#{host}/cgi-bin/"
    @username = username
    @password = passwd
    @deteccion = detec
    @auth_id = Base64.encode64("#{username}:#{passwd}") if username
  end
  
  # sends the camera to the home position
  def centro
    @control_url = "#{@control_url}camctrl.cgi"
    send_command("PanTiltSingleMove" => 4)
  end
  
  def arriba
    @control_url = "#{@control_url}camctrl.cgi"
    send_command("move" => "up")
  end
  def abajo
    @control_url = "#{@control_url}camctrl.cgi"
    send_command("move" => "down")
  end
  def izquierda
    @control_url = "#{@control_url}camctrl.cgi"
    send_command("move" => "left")
  end
  def derecha
    @control_url = "#{@control_url}camctrl.cgi"
    send_command("move" => "right")
  end
  def moverCamara(direccion)
  	if direccion == "arriba" || direccion == "up"
      arriba()
    elsif direccion == "abajo" || direccion == "down"
      abajo()
    elsif direccion == "izquierda" || direccion == "left"
      izquierda()
    elsif direccion == "derecha" || direccion == "right"
      derecha()
    elsif direccion == "center" || direccion == "home"
      centro()
    end

  end
  def getImage
    #logger.debug " Peticion de imagen "
    @control_url = "#{@control_url}video.jpg"
    imagen = send_command()
    #logger.debug "Imagen en string"
    #logger.debug "#{imagen}"
    #logger.debug "En Encode "
    #logger.debug "#{Base64.encode64(imagen)}"
    return Base64.encode64(imagen)
  end
  def getInfoGeneral
    #logger.debug " Peticion de imagen "
    @control_url = "#{@control_url}admin/configfile.cgi"
    respuesta = send_command()
    modelo = respuesta.partition("<modelname>")[0].partition(' ')[0]
    nombre = respuesta.partition("<host name>")[0].partition(' ')[0]
    fecha = respuesta.partition("<current date>")[0].partition(' ')[0]
    hora = respuesta.partition("<current time>")[0].partition(' ')[0]
    usuario = respuesta.partition("<user name>")[0].partition(' ')[0]
    clave = respuesta.partition("<user password>")[0].partition(' ')[0]
    #logger.debug "PROBANDO ARRAYArribAA #{respuesta2}"
    ##logger.debug "PROBANDO ARRAYAbajo #{respuesta2[2].partition(/\s+|\t+|\n+|\r+|/)}"
    #logger.debug "Modelo #{modelo} nombre #{nombre} fecha #{fecha} hora #{hora} usuario #{usuario} clave #{clave}"
  end

  private 
  # sends a command to the camera
  def send_command(parms=nil)
    #logger.debug "AQUIII ESTOOOY "


    url = URI.parse(@control_url)
    #logger.debug "URL  #{@control_url}"
    req = Net::HTTP::Get.new(url.path)


    #logger.debug "URLpath  #{url.path}"
    if parms
		#logger.debug "sent data #{parms.to_json}"
    end
    

    req.basic_auth @username, @password if @username
    if parms
		req.set_form_data(parms)
    end
    
    
    res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    res.use_ssl = true if @control_url =~ /^https/
    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
      #logger.debug "REspuesta #{res}"
      return res.body
    else
      res.error!
    end
  end
end
