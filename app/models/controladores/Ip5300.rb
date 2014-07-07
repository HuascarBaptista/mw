# -*- encoding : utf-8 -*-
require "base64"
require "uri"
require "socket"
require "net/http"
require "cgi"

class Ip5300
	
	UP = 1
	DOWN = -1
	RIGHT = 1
	LEFT = -1
	@auth_id = nil
	@username = nil
	@password = nil
	@deteccion = nil
	@host = nil
	# constructor. Username and password are optional. If you don't specify them 
	def initialize(host, username = nil, passwd = nil,detec = nil)
		@host = host
		@control_url = "http://#{host}/cgi-bin/"
		@username = username
		@password = passwd
		@deteccion = detec
		@auth_id = Base64.encode64("#{@username}:#{@password}") if @username
	end
	
	#Envía la camara a la posición inicial
	def centro
		begin
			respuesta = send_command_get("move" => "home")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Mueve la cámara para arriba
	def arriba
		begin
			respuesta = send_command_get("move" => "up")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Mueve la cámara para abajo
	def abajo
		begin
			respuesta =  send_command_get("move" => "down")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Mueve la cámara para la izquierda
	def izquierda
		begin
			respuesta = send_command_get("move" => "left")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Mueve la cámara para la derecha
	def derecha
		begin
			respuesta = send_command_get("move" => "right")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Detecta el movimiento que desea realizar el usuario con la cámara
	def moverCamara(direccion)
		@control_url = "#{@control_url}camctrl.cgi"
		if direccion == "arriba" || direccion == "up"
			return arriba()
		elsif direccion == "abajo" || direccion == "down"
			return abajo()
		elsif direccion == "izquierda" || direccion == "left"
			return izquierda()
		elsif direccion == "derecha" || direccion == "right"
			return derecha()
		elsif direccion == "centro" || direccion == "home" || direccion == "center" 
			return centro()
		end
	end
	#Cambia el nombre de usuario y la clave en la cámara
	def setAutenticacion(ip_nueva,puerto_nueva,usuario_nueva,clave_nueva)
		#Rails.#Rails.logger.debug "Arriba"
		#Agregamos el usuario nuevo
		@control_url = "http://#{@host}/setup/security.cgi"
		begin
			respuesta = send_command_post("username"=>usuario_nueva,"userpass"=>clave_nueva,"dido"=>"yes","pt"=>"yes")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			#Rails.#Rails.logger.debug "autenticacion #{t}"
			return "autenticacion"
		end

		sleep 5

		if @username != "admin"

			@username = usuario_nueva
			@password = clave_nueva
			@auth_id = Base64.encode64("#{usuario_nueva}:#{clave_nueva}") if usuario_nueva

			#Rails.#Rails.logger.debug "Abajo"
			#Eliminamos al otro
			@control_url = "http://#{@host}/setup/security.cgi"
			#Rails.#Rails.logger.debug "__________________-------------------------Eliminar"
			begin
				#respuesta = send_command_post("deluser"=>@username)
			rescue Errno::ETIMEDOUT  => e
				return "camara"
			rescue Exception => t
				
				if t.message.include? "No such host is known"
					return "camara"
				end
				#Rails.#Rails.logger.debug "autenticacion"
				return "autenticacion"
			end


			sleep 5

			@username = usuario_nueva
			@password = clave_nueva
			@auth_id = Base64.encode64("#{usuario_nueva}:#{clave_nueva}") if @username

		end

		#Cambiamos Ip
		@control_url = "http://#{@host}/setup/network.cgi"
		#Rails.#Rails.logger.debug "IP"
		begin
			respuesta = send_command_post("ip"=>ip_nueva,"http"=>puerto_nueva)
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			#Rails.#Rails.logger.debug "Ip autenticacion"
			return "autenticacion"
		end

		#"deluser" elimianr usuario
		#POST cambiar password rootpass=test123,passchange=1,confirm=test123
		#agregar Usuario "username=asd&userpass=asd&dido=yes&pt=yes"
		
		if respuesta.present? && respuesta != "res.error"

			return "success"
		else
			return nil
		end
	
	end
	def configuracionInicial

			
			@control_url = "http://#{@host}/setup/app.cgi"

			begin
				respuesta = send_command_post("snapsize" => "2", "smethod" => "ftp")  
			rescue Errno::ETIMEDOUT  => e
				return "camara"
			rescue Exception => t
				return "autenticacion"
			end
			
			if respuesta.present? && respuesta != "res.error"
				return "success"
			else
				return res.error
			end
			
	end
	def setTamano
		@control_url = "http://#{@host}/setup/video.cgi"
		begin
			respuesta = send_command_post("size"=>"5")  
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end

	def setFtp(host,port,usuario,clave,path)
		##Rails.##Rails.#Rails.logger.debug "--- SET FTP ---"
		@control_url = "http://#{@host}/setup/network.cgi"
		##Rails.##Rails.#Rails.logger.debug "#{@control_url}"
		begin
			respuesta = send_command_post("ftp1"=>host,"ftpp"=>port,"fuser1"=>usuario,"fpass1"=>clave,"ffd1"=>path)  
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return res.error
		end
	end

	def deteccionMovimiento(nombre,x1,y1,w1,h1,p1,t1)
		##Rails.##Rails.#Rails.logger.debug "---SET deteccionMovimiento ---"
		@control_url = "http://#{@host}/setup/video.cgi"

		##Rails.##Rails.#Rails.logger.debug "#{@control_url}"
		begin
			respuesta = send_command_post("enablemd"=>"yes","action"=>"change")  
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		if respuesta.present? && respuesta != "res.error"

			##Rails.##Rails.#Rails.logger.debug "---SET deteccionMovimiento ---"
			@control_url = "http://#{@host}/setup/app.cgi"
			##Rails.##Rails.#Rails.logger.debug "#{@control_url}"
			begin
				respuesta = send_command_post("sun"=>"yes","mon"=>"yes","tue"=>"yes","wed"=>"yes",
						"thu"=>"yes","fri"=>"yes","sat"=>"yes","sbegin"=>"00 00 00","send"=>"00 00 00",
						"emode"=>"yes","delay"=>"3","inter"=>"1","motion1"=>"yes",
						"mdupload"=>"yes","snapsize"=>"2","sinter"=>"1","smethod"=>"ftp","suffix"=>"yes") 
			rescue Errno::ETIMEDOUT  => e
				return "camara"
			rescue Exception => t
				return "autenticacion"
			end
			if respuesta.present? && respuesta != "res.error"
				@control_url = "http://#{@host}/setup/setmd.cgi"
				##Rails.##Rails.#Rails.logger.debug "#{@control_url}"
				begin
					respuesta = send_command_get("n1"=>nombre,"x1"=>x1,"y1"=>y1,"w1"=>w1,"h1"=>h1,"p1"=>p1,"t1"=>t1)  
				rescue Errno::ETIMEDOUT  => e
					return "camara"
				rescue Exception => t
					return "autenticacion"
				end
				return "success"
			end
		else
			return res.error
		end

	end

	#Retorna una imagen en tiempo real de la cámara en formato de string 
	def obtenerImagen
		##Rails.##Rails.#Rails.logger.debug "---AQUI ---"
		@control_url = "#{@control_url}video.jpg"
		begin
			imagen = send_command_get()  
		rescue Errno::ETIMEDOUT  => e
			#Rails.##Rails.#Rails.logger.debug "-- EXPECI--- Exception #{t} El mensaje #{t.message} "
			return "camara"
		rescue Exception => t
			#Rails.#Rails.logger.debug "-- EXPECI--- Exception #{t} El mensaje #{t.message} "
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			if t.message.include? "No connection could be made because the target machine actively refused it"
				return "No connection could be made because the target machine actively refused it"
			end
			return "autenticacion"
		end
		#Rails.##Rails.#Rails.logger.debug "-- LIBRE--- "
		if imagen.present? && imagen != "res.error"
			return Base64.encode64(imagen)
		else
			return "foto"
		end
	end
	def getInfoGeneral
		###Rails.#Rails.logger.debug " Peticion de imagen "
		@control_url = "#{@control_url}admin/configfile.cgi"
		respuesta = send_command_get()
		modelo = respuesta.partition("<modelname>")[0].partition(' ')[0]
		nombre = respuesta.partition("<host name>")[0].partition(' ')[0]
		fecha = respuesta.partition("<current date>")[0].partition(' ')[0]
		hora = respuesta.partition("<current time>")[0].partition(' ')[0]
		usuario = respuesta.partition("<user name>")[0].partition(' ')[0]
		clave = respuesta.partition("<user password>")[0].partition(' ')[0]
		###Rails.#Rails.logger.debug "PROBANDO ARRAYArribAA #{respuesta2}"
		####Rails.#Rails.logger.debug "PROBANDO ARRAYAbajo #{respuesta2[2].partition(/\s+|\t+|\n+|\r+|/)}"
		###Rails.#Rails.logger.debug "Modelo #{modelo} nombre #{nombre} fecha #{fecha} hora #{hora} usuario #{usuario} clave #{clave}"
	end

	private 
	# sends a command to the camera
	def send_command_post(parms)
			#Rails.#Rails.logger.debug "---AQUI "
			url = URI.parse(@control_url)
			req = Net::HTTP::Post.new(url.path)

			##Rails.##Rails.#Rails.logger.debug "---AQUI send_command_post --- "
			##Rails.##Rails.#Rails.logger.debug "--- Port #{url.port} ----" 
			##Rails.##Rails.#Rails.logger.debug "--- Path #{url.path} ----" 
			##Rails.##Rails.#Rails.logger.debug "--- Params #{parms} ----"  
			#Rails.#Rails.logger.debug "--- username #{@username} ----"  
			#Rails.#Rails.logger.debug "--- password #{@password} ----"  
			

			req.basic_auth @username, @password if @username
			if parms.present?
			req.set_form_data(parms)
			end
			begin
				#print "sent data #{parms.to_json}"
				res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
				res.use_ssl = true if @control_url =~ /^https/
				case res
				when Net::HTTPSuccess, Net::HTTPRedirection
					# OK
					return res.body
				when Net::HTTPNotFound
					raise "No such host is known"
				else
					##Rails.##Rails.#Rails.logger.debug "ERROR HTTP #{res.error}"
					raise res.error!
				end
			rescue Exception => t
				##Rails.##Rails.#Rails.logger.debug "Exception In post #{t}"
				###Rails.#Rails.logger.debug "Respuesta Errada CATCH : #{res}"
				raise t
			end
	end

	# sends a command to the camera
	def send_command_get(parms=nil)
			url = URI.parse(@control_url)
			req = Net::HTTP::Get.new(url.path)

			#Rails.#Rails.logger.debug "---AQUI send_command_get --- "
			#Rails.#Rails.logger.debug "--- Url #{@control_url} ----" 
			##Rails.##Rails.#Rails.logger.debug "--- Path #{url.path} ----" 
			#Rails.#Rails.logger.debug "--- Params #{parms} ----" 

			###Rails.#Rails.logger.debug "URLpath  #{url.path}"
			req.basic_auth @username, @password if @username
			if parms.present?
				req.set_form_data(parms)
			end
			begin
				res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
				res.use_ssl = true if @control_url =~ /^https/
				case res
				when Net::HTTPSuccess, Net::HTTPRedirection
					# OK
					###Rails.#Rails.logger.debug "Respuesta #{res}"
					return res.body
				when Net::HTTPNotFound
					raise "No such host is known"
				else
					##Rails.##Rails.#Rails.logger.debug "ERROR HTTP #{res.error}"
					###Rails.#Rails.logger.debug "Respuesta Errada : #{res}"
					raise res.error!
				end  
			rescue Exception => t
				##Rails.##Rails.#Rails.logger.debug "Exception #{t}"
				###Rails.#Rails.logger.debug "Respuesta Errada CATCH : #{res}"
				raise t
			end
	end
end
