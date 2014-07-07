# This runs a simple sinatra app as a service
require 'net/ftp'

#APP_ROOT_CUSTOM = 'C:/Users/CamTeam/Documents/Tesis Huascar Milagros/Dropbox/Milagros/Tesis/mw/'
#APP_ROOT_CUSTOM = 'C:/Users/CamTeam/Documents/Tesis Huascar Milagros/Dropbox/Milagros/Tesis/mw/'
APP_ROOT_CUSTOM = 'C:/Users/Luis/Dropbox/Tesis (Carpeta la web)/Dropbox/Milagros/Tesis/mw/' 
LOG_FILE = APP_ROOT_CUSTOM + 'log/fotosDeteccion.log'
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
	
	
	File.open(LOG_SERVICIOS_FILE, "a"){ |f| f.puts "Servicio FotosDeteccion iniciado #{Time.now}" }
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
		File.open(LOG_FILE,'a+'){ |f| f.puts " Solicitando fotos:  #{Time.now}" }
		sleep 5
		begin
			checkImages()
		rescue Exception => err
			File.open(LOG_FILE,'a+'){ |f| f.puts "Error en SendImages #{Time.now} err=#{err}"}
			raise
		end
	end

	 def checkImages
		ftpp = Ftp.all.first

		if !ftpp.present?
			File.open(LOG_FILE,'a+'){ |f| f.puts "FTP no seteado #{Time.now}"}
			return
		end
		threads = []
		camaras = Camara.where(:defectuosa=>"0")
		camaras.each do |camara|
			File.open(LOG_FILE,'a+'){ |f| f.puts "Comprobando fotos #{Time.now} en FTP  de la camara  #{camara.ip}" }
			ftp = objetoFtp(ftpp,camara.ip)
			files = ftp.nlst("*.jpg")|ftp.nlst("*.jpeg")|ftp.nlst("*.png")

			files.each do |file|
				#do something with each file here
				File.open(LOG_FILE,'a+'){ |f| f.puts "Archivo en FTP #{Time.now} #{file}" }
				begin
					#nombreArchivo = File.basename(file.path)
					i =0  
					name =File.basename(file, '.*')
					nombre_temp = sanitize_filename(camara.ip+"-#{name}")
					extension = File.extname(file)
					File.open(LOG_FILE,'a+'){ |f| f.puts "Creamos carpeta en local #{Time.now}" }

					if !File.exist?("app/assets/imagenesCamaras"+"/#{sanitize_filename(camara.id)}/")
						#Se crea el directorio
						FileUtils.mkdir_p(File.dirname(__FILE__) +"/../assets/imagenesCamaras"+"/#{sanitize_filename(camara.id)}/") 
					end
					nombre = File.dirname(__FILE__) +"/../assets/imagenesCamaras"+"/#{sanitize_filename(camara.id)}/#{nombre_temp}"
					while File.exist?(nombre)
						nombre_temp = sanitize_filename(nombre_temp +"-"+i.to_s)
						nombre = File.dirname(__FILE__) +"/../assets/imagenesCamaras"+"/#{sanitize_filename(camara.id)}/#{nombre_temp}"
						i=i+1
					end
					File.open(LOG_FILE,'a+'){ |f| f.puts "Bajamos el archivo a Local #{Time.now}" }
					ftp.getbinaryfile(file,nombre+extension)
					File.open(LOG_FILE,'a+'){ |f| f.puts "Cambiamos el nombre al archivo remoto #{Time.now}" }
					
					
					#Enviar la foto a todos los scripts
					autenticacion_camaras = AutenticacionCamara.where(:camara_id => camara.id)
					autenticacion_camaras.each do |autenticacion|
						##logger.debug.debug "El id autenticacion #{autenticacion.autenticacion_id}"
						script_imagen = ScriptImagen.where(:autenticacion_id => autenticacion.autenticacion_id).first
						autenticacion = Autenticacion.where(:id => autenticacion.autenticacion_id).first
						camara_ip =camara.ip

						url = "http://localhost:3001/assets"+"/#{sanitize_filename(camara.id)}/#{nombre_temp}#{extension}"
						server_id = autenticacion.server_id
						server_key = autenticacion.server_key
						deteccion_movimiento = "1"
						script = script_imagen.script
						parametros ={"accion"=>"enviar_foto","url"=>url,"camara_ip"=>camara_ip,"server_key"=>server_key,
						"server_id"=>server_id,"deteccion_movimiento"=>deteccion_movimiento,'fecha'=>"#{ftp.mtime(file)}"}
						threads << Thread.new do
							sleep 5
							begin
								respuesta = send_command_post(parametros,script)    
								parametros = parametros.to_json
								File.open(LOG_FILE, "a"){ |f| f.puts "Foto enviada #{Time.now} de la camara  #{camara.ip} Parametros: #{parametros} Url:#{script} Respuesta:#{respuesta}" } 
								begin
									
									ftp.rename(file, ftp.pwd()+"/listos/#{rand(987654321)}-#{File.basename(file)}")
								rescue Exception => e
									File.open(LOG_FILE, "a"){ |f| f.puts "Error cambiando foto #{Time.now}  #{e}" } 
								end
							rescue Exception => e

								File.open(LOG_FILE, "a"){ |f| f.puts "Error enviando foto #{Time.now} de la camara  #{camara.ip}: #{e} Parametros: #{parametros} Url:#{script} " } 
							end
						end
					end
				rescue Exception => err
					File.open(LOG_FILE,'a+'){ |f| f.puts "Error moviendo imagen #{file} #{err}" }
				end
			end
		end
		threads.each(&:join)
	end

	def sanitize_filename(filename)
	      filename = "#{filename}"
	      filename.gsub(/[^0-9A-z.\-]/, '_')
    	end	
	def archivoExiste(ftp=nil,archivo)
		if !ftp.present?
			begin
				ftp = conectar
			rescue Exception => e
				raise "#{e}"
			end
		end
		return !ftp.nlst(archivo).empty?
	end


	def objetoFtp(ftpp,ipCamara)

		camara = Camara.ipToCamara(ipCamara)
		File.open(LOG_FILE,'a+'){ |f| f.puts "Seteando FTP #{Time.now} de la camara  #{camara.ip}" }
		if ftpp.path[-1,1]!="/"
			ftpp.path+="/"
			ftpp.save
		end
		if ftpp.path[0,1]!="/"
			ftpp.path="/#{ftp.path}"
			ftpp.save
		end
		if ftpp.path[-1,1]!="/"
			ruta = "#{ftpp.path}/#{camara.id}/listos/"
		else
			ruta = "#{ftpp.path}#{camara.id}/listos/"
		end
		File.open(LOG_FILE,'a+'){ |f| f.puts "Seteando FTP #{Time.now} ruta #{ruta}" }
		begin
			ftp = conectar(ftpp.host,ftpp.puerto,ftpp.usuario,ftpp.clave,ftpp.path)
			crearDir(ftp,"#{ruta}")
		rescue Exception => e
			#logger.debug "EL ERROR SETEANDO FTP CREANDO DIR #{e}"
			File.open(LOG_FILE,'a+'){ |f| f.puts "Seteando FTP #{Time.now} ERROR #{e}" }
			return false
		end
		if ftpp.path[-1,1]!="/"
			ftpp.path+="/"
			ftpp.save
		end
		if ftpp.path[0,1]!="/"
			ftpp.path="/#{ftp.path}"
			ftpp.save
		end
		if ftpp.path[-1,1]!="/"
			ruta = "#{ftpp.path}/#{camara.id}/"
		else
			ruta = "#{ftpp.path}#{camara.id}/"
		end
		begin
			ftp = conectar(ftpp.host,ftpp.puerto,ftpp.usuario,ftpp.clave,ftpp.path)
			crearDir(ftp,"#{ruta}")
		rescue Exception => e
			#logger.debug "EL ERROR SETEANDO FTP CREANDO DIR #{e}"
			File.open(LOG_FILE,'a+'){ |f| f.puts "Seteando FTP #{Time.now} ERROR ABAJO  #{e}" }
			return false
		end

		return ftp
	end

	def cambiarDir(ftp=nil,directorio)
		 if !ftp.present?
			begin
				ftp = conectar
			rescue Exception => e
				raise "#{e}"
			end
		end
		begin 
			carpeta=""
			carpetas = directorio.split("/")
			carpetas.each do |folder|
				carpeta+="/#{folder}"
				begin
					ftp.chdir(carpeta)

				rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
					ftp.mkdir(carpeta)
				end


			end
			ftp.chdir(directorio)
		rescue Exception => e
			raise "#{e}"
		end
	end
	def crearDir(ftp=nil,directorio)
		 if !ftp.present?
			begin
				ftp = conectar
			rescue Exception => e
				raise "#{e}"
			end
		end
		begin 
			carpeta=""
			carpetas = directorio.split("/")
			carpetas.each do |folder|
				carpeta+="/#{folder}"
				begin
					ftp.chdir(carpeta)

				rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
					ftp.mkdir(carpeta)
				end


			end
			ftp.chdir(directorio)
		rescue Exception => e
			raise "#{e}"
		end
		#ftp.close
	end
	def conectar(host=nil,puerto=nil,usuario=nil,clave=nil,path=nil)
		if !host.present?
			ftpp = Ftp.all.first
			if !ftpp.present?
				raise "No tiene FTP configurado"
			end
			host = ftpp.host
			puerto = ftpp.puerto
			usuario = ftpp.usuario
			clave = ftpp.clave
			path = ftpp.path

		end

		begin
			
			ftp=Net::FTP.new
			ftp.connect(host,puerto)
			ftp.login(usuario,clave)

			begin 
				carpeta=""
				carpetas = path.split("/")
				carpetas.each do |folder|
					carpeta+="/#{folder}"
					begin
						ftp.chdir(carpeta)

					rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
						ftp.mkdir(carpeta)
					end


				end

				ftp.chdir(path)
			rescue Exception => e
				raise "#{e}"
			end
			ftp.passive = true
			return ftp  
		rescue Exception => e
			raise "#{e}"
		end
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
	File.open(LOG_SERVICIOS_FILE,'a+'){ |f| f.puts "Error en el servicio FotosDeteccion #{Time.now} Error:#{err} " }
	raise
end

