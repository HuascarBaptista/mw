# This runs a simple sinatra app as a service

#APP_ROOT_CUSTOM = 'C:/Users/CamTeam/Documents/Tesis Huascar Milagros/Dropbox/Milagros/Tesis/mw/'
APP_ROOT_CUSTOM = 'C:/Users/Luis/Dropbox/Tesis (Carpeta la web)/Dropbox/Milagros/Tesis/mw/' 
#APP_ROOT_CUSTOM = 'C:/Dropbox/Milagros/Tesis/mw/'
LOG_FILE = APP_ROOT_CUSTOM + 'log/comprobarCamara.log'
LOG_SERVICIOS_FILE = APP_ROOT_CUSTOM + 'log/servicios.log'
APP_PATH = File.expand_path( APP_ROOT_CUSTOM  + 'config/application', APP_ROOT_CUSTOM  + 'bin/rails')

require 'rubygems'
require 'daemons'
#require File.expand_path( APP_ROOT_CUSTOM  + 'config/boot.rb', APP_ROOT_CUSTOM  + 'bin/rails')
require 'rails/commands/server'
require 'active_record'
require 'mysql2' # or 'pg' or 'sqlite3'
require "base64"
require "uri"
require "socket"
require "net/http"
require "cgi"

# Change the following to reflect your database settings
ActiveRecord::Base.establish_connection(
  adapter:  'mysql2', # or 'postgresql' or 'sqlite3'
  host:     'localhost',
  database: 'test',
  username: 'test',
  password: ''
)
begin
  
    File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio ComprobarCamara iniciado #{Time.now}" }
    File.open(LOG_FILE,'a+'){ |f| f.puts " Cargando modelos #{Time.now} " }
    Dir[File.dirname(__FILE__) +"/../models/*.rb"].each do |file| 
      begin
        require file
        File.open(LOG_FILE,'a+'){ |f| f.puts "Modelo #{file} cargado" }
      rescue Exception => err
        File.open(LOG_FILE,'a+'){ |f| f.puts "Error cargando modelo #{file}" }
      end
    end

    Dir[File.dirname(__FILE__) +"/../models/controladores/*.rb"].each do |file| 
      begin
        require file
        File.open(LOG_FILE,'a+'){ |f| f.puts "Modelo #{file} cargado" }
      rescue Exception => err
        File.open(LOG_FILE,'a+'){ |f| f.puts "Error cargando modelo #{file}" }
      end
    end
    loop do
      File.open(LOG_FILE,'a+'){ |f| f.puts " Comprobando camaras:  #{Time.now}" }
      sleep 5
      begin
        comprobarCamaras()
      rescue Exception => err
        File.open(LOG_FILE,'a+'){ |f| f.puts "Error en comprobarCamaras #{Time.now} err=#{err}"}
        raise
      end
    end

    def getImage(ipp)
      if ipp =="190.169.70.145"
        return "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"
      end
      ip = ipp
      camara=Camara.where(:ip=>ip).first
      unless camara 
         return nil
      end
      
      modelo = Camara.ipToModel(ip)
      if modelo
        script = modelo.objeto.constantize
        begin
          c = script.new(camara.ip, camara.usuario, camara.contrasena)
        rescue Errno::ETIMEDOUT  => e
          raise "Camara inalcanzable"
        rescue Exception => t
          
          if t.message.include? "No such host is known"
            raise "Camara inalcanzable"
          end
          
          raise "Mala autenticacion"
        end
        #logger.debug.debug "El objeto  #{c}"
        foto = c.obtenerImagen
        if foto == "camara"
          raise "Camara inalcanzable"
        elsif foto=="autenticacion"
          raise "Mala autenticacion"
        elsif foto=="foto"
          raise "Foto danada"
        end
      else
        return nil
      end
      return foto
    end
    def sanitize_filename(filename)
      filename = "#{filename}"
      filename.gsub(/[^0-9A-z.\-]/, '_')
    end

    def camaraDefectuosa(camara)
      threads2 = []
      camara.defectuosa ="1"
      camara.save
      #Enviar la foto a todos los scripts
      autenticacion_camaras = AutenticacionCamara.where(:camara_id => camara.id)
      autenticacion_camaras.each do |autenticacion|
        #logger.debug.debug "El id autenticacion #{autenticacion.autenticacion_id}"
         script_imagen = ScriptImagen.where(:autenticacion_id => autenticacion.autenticacion_id).first
         autenticacion = Autenticacion.where(:id => autenticacion.autenticacion_id).first
        camara_ip =camara.ip
        server_id = autenticacion.server_id
        server_key = autenticacion.server_key
        script = script_imagen.script
        parametros ={"accion"=>"camara_defectuosa","camara_ip"=>camara_ip,"server_key"=>server_key,
          "server_id"=>server_id,"defectuosa"=>"1"}
        threads2 << Thread.new do
          begin
            respuesta = send_command_post(parametros,script)    
            parametros = parametros.to_json
            File.open(LOG_FILE, "a"){ |f| f.puts "Camara defectuosa #{Time.now} IP:  #{camara.ip} Parametros: #{parametros} Url:#{script} Respuesta:#{respuesta}" } 
          rescue Exception => e
            File.open(LOG_FILE, "a"){ |f| f.puts "Error enviando camara defectuosa #{Time.now} IP:  #{camara.ip}: #{e} Parametros: #{parametros} Url:#{script} " } 
          end
        end
      end
      threads2.each(&:join)
    end
    def camaraDisponible(camara)
      threads2 = []
      camara.defectuosa ="0"
      camara.save
      #Enviar la foto a todos los scripts
      autenticacion_camaras = AutenticacionCamara.where(:camara_id => camara.id)
      autenticacion_camaras.each do |autenticacion|
        #logger.debug.debug "El id autenticacion #{autenticacion.autenticacion_id}"
         script_imagen = ScriptImagen.where(:autenticacion_id => autenticacion.autenticacion_id).first
         autenticacion = Autenticacion.where(:id => autenticacion.autenticacion_id).first
        camara_ip =camara.ip
        server_id = autenticacion.server_id
        server_key = autenticacion.server_key
        script = script_imagen.script
        parametros ={"accion"=>"camara_defectuosa","camara_ip"=>camara_ip,"server_key"=>server_key,
          "server_id"=>server_id,"defectuosa"=>"0"}
        threads2 << Thread.new do
          begin
            respuesta = send_command_post(parametros,script)    
            parametros = parametros.to_json
            File.open(LOG_FILE, "a"){ |f| f.puts "Camara disponible #{Time.now} IP:  #{camara.ip} Parametros: #{parametros} Url:#{script} Respuesta:#{respuesta}" } 
          rescue Exception => e
            File.open(LOG_FILE, "a"){ |f| f.puts "Error enviando camara disponible #{Time.now} IP:  #{camara.ip}: #{e} Parametros: #{parametros} Url:#{script} " } 
          end
        end
      end
      threads2.each(&:join)
    end
    def comprobarCamaras
      threads = []
      camaras = Camara.all
      camaras.each do |camara|
        File.open(LOG_FILE,'a+'){ |f| f.puts "Solicitando imagen #{Time.now} de la camara  #{camara.ip}" }
        begin
          foto = getImage(camara.ip)

          File.open(LOG_FILE,'a+'){ |f| f.puts "Capture imagen? #{Time.now} de la camara  #{camara.ip} antes defectuosa? #{camara.defectuosa} #{camara.defectuosa == true} - #{camara.defectuosa == "1"}" }

          if camara.defectuosa == 1
            camaraDisponible(camara)
          end
        rescue Exception => t
          File.open(LOG_FILE,'a+'){ |f| f.puts "Error en la camara #{camara.ip}: #{t} " }
          camaraDefectuosa(camara)
        end

        if foto.present?
          
        else
          File.open(LOG_FILE,'a+'){ |f| f.puts "Error en la camara #{camara.ip}, posible foto danada" }
          #camaraDefectuosa(camara)
        end
      end
      threads.each(&:join)
    end

    def send_command_post(parms,script)
      control_url = script
      url = URI.parse(control_url)
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth @username, @password if @username
      if parms.present?
        req.set_form_data(parms)
      end
      #print "sent data #{parms.to_json}"
      res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      res.use_ssl = true if @control_url =~ /^https/
      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        # OK
        return res.body
      else
        raise res.error!
      end
    end

rescue Exception => err
  File.open(LOG_SERVICIOS_FILE,'a+'){ |f| f.puts "Error en el servicio ComprobarCamara #{Time.now} Error:#{err} " }
  raise
end

