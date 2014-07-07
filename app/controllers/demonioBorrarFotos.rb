# This runs a simple sinatra app as a service

#APP_ROOT_CUSTOM = 'C:/Users/CamTeam/Documents/Tesis/Dropbox/Milagros/Tesis/mw/'
#APP_ROOT_CUSTOM = 'C:/Dropbox/Milagros/Tesis/mw/'
#APP_ROOT_CUSTOM = 'C:/Users/Luis/Dropbox/Tesis (Carpeta la web)/Dropbox/Milagros/Tesis/mw/' 
APP_ROOT_CUSTOM = 'C:/Users/Luis/Dropbox/Tesis/Dropbox/Milagros/Tesis/mw/'
LOG_FILE = APP_ROOT_CUSTOM + 'log/borrarFotos.log'
LOG_SERVICIOS_FILE = APP_ROOT_CUSTOM + 'log/servicios.log'
APP_PATH2 = File.expand_path( APP_ROOT_CUSTOM  + 'config/application', APP_ROOT_CUSTOM  + 'bin/rails')

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
			File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio BorrarFotos iniciado #{Time.now}" }
			Dir[File.dirname(__FILE__) +"/../models/*.rb"].each do |file| 
				begin
					require file
				rescue Exception => err
				end
			end

			Dir[File.dirname(__FILE__) +"/../models/controladores/*.rb"].each do |file| 
				begin
					require file
				rescue Exception => err
				end
			end
			tiempoo=0
			while running?
				sleep 60*60*23
				begin
					BorrarFotos()
				rescue Exception => err
					File.open(LOG_FILE,'a+'){ |f| f.puts "Error en BorrarFotos #{Time.now} err=#{err}"}
					raise
				end
			end
		end 

		def service_stop(*args)
			File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio BorrarFotos detenido #{Time.now}" }
			exit! 
		end

		def sanitize_filename(filename)
			filename = "#{filename}"
			 filename.gsub(/[^0-9A-z.\-]/, '_')
		 end
		 def existe
			return File.exist?(File.dirname(__FILE__)+"/../../temporal.txt")
		end
		def leer
			if existe
				return File.read(File.dirname(__FILE__)+"/../../temporal.txt")
			else
				return "15"
			end
		end 

		def BorrarFotos
			tiempo_borrado = leer.to_i
			threads = []
			camaras = Camara.all
			camaras.each do |camara|
				carpeta =File.dirname(__FILE__)+"/../../"+"app/assets/imagenesCamaras"+"/#{camara.id}/"

				if File.exist?(carpeta)
					selected_files = Dir.glob(carpeta+"*.*").select do |file|
						mtime = File.mtime(file)

						if ( (Time.now - mtime).to_i / (24 * 60 * 60)  ) > tiempo_borrado
							File.delete(file)
							File.open(LOG_FILE, "a"){ |f| f.puts "Imagen borrada #{File.basename(file)}  de la camara #{camara.id} #{Time.now}" }
						end
					end
				end
			end
			threads.each(&:join)
		end

		DemoDaemon.mainloop
	end
rescue Exception => err
	File.open(LOG_SERVICIOS_FILE,'a+'){ |f| f.puts "Error en el servicio BorrarFotos #{Time.now} Error:#{err} " }
end
