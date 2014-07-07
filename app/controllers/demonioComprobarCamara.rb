# This runs a simple sinatra app as a service

#APP_ROOT_CUSTOM = 'C:/Users/CamTeam/Documents/Tesis/Dropbox/Milagros/Tesis/mw/'
#APP_ROOT_CUSTOM = 'C:/Dropbox/Milagros/Tesis/mw/'
APP_ROOT_CUSTOM = 'C:/Users/Luis/Dropbox/Tesis/Dropbox/Milagros/Tesis/mw/'
LOG_FILE = APP_ROOT_CUSTOM + 'log/comprobarCamara.log'
LOG_SERVICIOS_FILE = APP_ROOT_CUSTOM + 'log/servicios.log'
APP_PATH5 = File.expand_path( APP_ROOT_CUSTOM  + 'config/application', APP_ROOT_CUSTOM  + 'bin/rails')

require 'rubygems'
require 'win32/daemon'
include Win32
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
  

  class DemoDaemon < Daemon
    def service_init
      
    end
    
    def service_main(*args)
      File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio ComprobarCamara iniciado #{Time.now}" }
      #File.open(LOG_FILE,'a+'){ |f| f.puts " Cargando modelos #{Time.now} " }
      Dir[File.dirname(__FILE__) +"/../models/*.rb"].each do |file| 
        begin
          require file
          #File.open(LOG_FILE,'a+'){ |f| f.puts "Modelo #{file} cargado" }
        rescue Exception => err
          #File.open(LOG_FILE,'a+'){ |f| f.puts "Error cargando modelo #{file}" }
        end
      end

      Dir[File.dirname(__FILE__) +"/../models/controladores/*.rb"].each do |file| 
        begin
          require file
          #File.open(LOG_FILE,'a+'){ |f| f.puts "Modelo #{file} cargado" }
        rescue Exception => err
          #File.open(LOG_FILE,'a+'){ |f| f.puts "Error cargando modelo #{file}" }
        end
      end
      while running?
        #File.open(LOG_FILE,'a+'){ |f| f.puts " Comprobando camaras:  #{Time.now}" }
        sleep 5
        begin
          comprobarCamaras()
        rescue Exception => err
          File.open(LOG_FILE,'a+'){ |f| f.puts "Error en comprobarCamaras #{Time.now} err=#{err}"}
          raise
        end
      end
    end 

    def service_stop(*args)
      File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio ComprobarCamara detenido #{Time.now}" }
      exit! 
    end

    def getImage(ipp)

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
        #File.open(LOG_FILE,'a+'){ |f| f.puts "Solicitando imagen #{Time.now} de la camara  #{camara.ip}" }
        begin
          foto = getImage(camara.ip)

          #File.open(LOG_FILE,'a+'){ |f| f.puts "Capture imagen? #{Time.now} de la camara  #{camara.ip} antes defectuosa? #{camara.defectuosa} #{camara.defectuosa == true} - #{camara.defectuosa == "1"}" }

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

   end

  DemoDaemon.mainloop
rescue Exception => err
  File.open(LOG_SERVICIOS_FILE,'a+'){ |f| f.puts "Error en el servicio ComprobarCamara #{Time.now} Error:#{err} " }
  raise
end

