# -*- encoding : utf-8 -*-

require "base64"
require "uri"
require "socket"
require "net/http"
require "cgi"

# This is the ruby driver for the Trendnet TV-IP400 or TV-IP400W IP camera. 
class Ip400
	UP = 1
	DOWN = -1
	RIGHT = 1
	LEFT = -1
	@auth_id = nil
	@username = nil
	@password = nil
	
	# constructor. Username and password are optional. If you don't specify them 
	# then make sure that User Access Control is disabled in the Trendnet configuration
	# interface. 
	def initialize(host, username = nil, passwd = nil,detec=nil)
		@control_url = "http://#{host}/"
		@username = username
		@password = passwd
		@auth_id = Base64.encode64("#{username}:#{passwd}") if username
		abs_position

		
		
	end
	
	
	
	# pans the camera a number of steps. Direction must be RIGHT or LEFT
	def pan(steps, direction)
		return move(steps, direction, 0, 0)
	end

#Envía la camara a la posición inicial
	def centro
		begin
			respuesta =  send_command_post("PanTiltSingleMove" => 4)
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
			respuesta = tilt(3, 1)
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		#Rails.##Rails.logger.debug "RESPUESTA ARRIBA #{respuesta}"
		if respuesta.present? && respuesta != "res.error"
			return "success"
		else
			return nil
		end
	end
	#Mueve la cámara para abajo
	def abajo
		begin
			respuesta =  tilt(3, -1)
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
			respuesta = pan(3, -1)
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
			respuesta = pan(3, 1)
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

	def setAutenticacion(ip_nueva,puerto_nueva,usuario_nueva,clave_nueva)

		@control_url ="#{@control_url}userlist.cgi"
		#Agrego al nuevo usuario
		begin
			respuesta = send_command_post("UserName"=>usuario_nueva,"UserPassword"=>clave_nueva,"UserPrivilege"=>"1","UserAdd"=>"Yes")
		rescue Errno::ETIMEDOUT  => e
			return "camara"
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		
		#Elimino al usuario viejo
			@control_url ="#{@control_url}userlist.cgi"
			begin
				respuesta2 = send_command_post("UserName"=>@username,"UserDelete"=>"Yes")
			rescue Errno::ETIMEDOUT  => e
				return "camara"
			rescue Exception => t
				return "autenticacion"
			end

			#Cambio la IP
			sleep 5

			@username = usuario_nueva
			@password = clave_nueva
			@auth_id = Base64.encode64("#{@username}:#{@password}") if @username
		
			@control_url ="#{@control_url}inetwork.cgi"
			begin
				respuesta3 = send_command_post("IPAddress"=>ip_nueva,"SecondaryHTTPPort"=>puerto_nueva)
			rescue Errno::ETIMEDOUT  => e
				return "camara"
			rescue Exception => t
				return "autenticacion"
			end

			if respuesta3.present? && respuesta3 != "res.error"
				return "success"
			else
				return nil
			end

	end

	def setTamano
		@control_url = "#{@control_url}image.cgi"
		begin
			respuesta = send_command_get("VideoResolution"=>"2")  
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
			##Rails.#Rails.##Rails.logger.debug "--- SET FTP ---"
		@control_url = "#{@control_url}upload.cgi"
		##Rails.#Rails.##Rails.logger.debug "#{@control_url}"
		begin
			respuesta = send_command_post("FTPHostAddress"=>host,"FTPHostPortNumber"=>port,"FTPUserName"=>usuario,"FTPPassword"=>clave,"FTPDirectoryPath"=>path,"ConfigFtp"=>"Save")  
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
		@control_url = "#{@control_url}PANTILTCONTROL.CGI"
		if direccion == "arriba" || direccion == "up"
			return arriba()
		elsif direccion == "abajo" || direccion == "down"
			return abajo()
		elsif direccion == "izquierda" || direccion == "left"
			return izquierda()
		elsif direccion == "derecha" || direccion == "right"
			return derecha()
		elsif direccion == "centro" || direccion == "home"
			return centro()
		end
	end
	def obtenerImagen
		
		##Rails.#Rails.##Rails.logger.debug "---AQUI ---"
		@control_url = "#{@control_url}image.jpg"
		begin
			imagen = send_command_get()  
		rescue Errno::ETIMEDOUT  => e
			##Rails.#Rails.##Rails.logger.debug "--- ERRNO #{e} "
			return "camara"
		rescue Exception => t
			##Rails.#Rails.##Rails.logger.debug "--- Exception image #{t} "
			if t.message.include? "No such host is known"
				return "camara"
			end
			
			return "autenticacion"
		end
		
		if imagen.present? && imagen != "res.error"
			return Base64.encode64(imagen)
		else
			return "foto"
		end
	end
	

	# tilts the camera a number of steps. Direction must be UP or DOWN
	def tilt(steps, direction)
		return move(0, 0, steps, direction)
	end
	
	# pans and tilts the camera at the same time.
	def move(pan_steps, pan_dir, tilt_steps, tilt_dir)
		if (pan_steps > 0 && pan_dir == RIGHT)
			if (tilt_steps > 0 && tilt_dir == UP)
				val = 2 # up right
			elsif (tilt_steps > 0 && tilt_dir == DOWN)
				val = 8 # down right
			else 
				val = 5 # right
			end
		elsif (pan_steps > 0 && pan_dir == LEFT)
			if (tilt_steps > 0 && tilt_dir == UP)
				val = 0 # up left
			elsif (tilt_steps > 0 && tilt_dir == DOWN)
				val = 6 # down left
			else 
				val = 3 # left
			end
		else 
			if (tilt_steps > 0 && tilt_dir == UP)
				val = 1 # up
			elsif (tilt_steps > 0 && tilt_dir == DOWN)
				val = 7 # down
			end # else: neither pan nor tilt
		end
		begin
			send_command_post("PanSingleMoveDegree" => pan_steps, "TiltSingleMoveDegree" => tilt_steps, "PanTiltSingleMove" => val)
			return true
		rescue Exception => e
			return e
		end
	end
 
	# returns the current absolute position of the camera as a hash with properties 
	# pan and tilt. If the position could not 
	def abs_position
		begin
			url = URI.parse(@control_url)
			socket = TCPSocket.new(url.host, url.port)
			socket.puts("GET /MJPEG.CGI HTTP/1.0\r\nUser-Agent: user\r\n")
			socket.puts("Authorization: Basic #{@auth_id}\r\n") if (@auth_id)
			socket.puts("\r\n");
			until (socket.readline == "\r\n"); end  # skip past the headers
			for i in 0..3
				m = socket.readline.match(/_PT_(\d{3})_(\d{3})/)
				if (m)
					pan, tilt = $1.to_i, $2.to_i
				end
			end
		rescue Exception => t
			raise t
		ensure
			socket.close if socket
		end
		
		if (pan && tilt)
			 #puts "pan #{pan} and tilt #{tilt}"
			 { "pan" => pan, "tilt" => tilt}
		else
			 #puts "couldn't get pan/tilt"
			 { "pan" => -1, "tilt" => -1}
		end
	end
	
	private 
	
	# sends a command to the camera
	def send_command_post(parms)
			##Rails.#Rails.##Rails.logger.debug "---AQUI "
			url = URI.parse(@control_url)
			req = Net::HTTP::Post.new(url.path)

			##Rails.#Rails.##Rails.logger.debug "---AQUI send_command_get --- "
			##Rails.#Rails.##Rails.logger.debug "--- Url #{@control_url} ----" 
			##Rails.#Rails.##Rails.logger.debug "--- Path #{url.path} ----" 
			##Rails.#Rails.##Rails.logger.debug "--- Params #{parms} ----"  
			

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
					Rails.##Rails.logger.debug "Cuerpo #{ res.body}"
					return res.body
				when Net::HTTPNotFound
					raise "No such host is known"
				else
					Rails.##Rails.logger.debug "ERROR HTTP #{res.error}"
					raise res.error!
				end
			rescue Exception => t
				Rails.##Rails.logger.debug "Exception in Post #{t}"
				##Rails.##Rails.logger.debug "Respuesta Errada CATCH : #{res}"
				raise t
			end
	end

	# sends a command to the camera
	def send_command_get(parms=nil)
			url = URI.parse(@control_url)
			req = Net::HTTP::Get.new(url.path)

			##Rails.#Rails.##Rails.logger.debug "---AQUI send_command_get --- "
			##Rails.#Rails.##Rails.logger.debug "--- Url #{@control_url} ----" 
			##Rails.#Rails.##Rails.logger.debug "--- Path #{url.path} ----" 
			##Rails.#Rails.##Rails.logger.debug "--- Params #{parms} ----" 

			##Rails.##Rails.logger.debug "URLpath  #{url.path}"
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
					##Rails.##Rails.logger.debug "Respuesta #{res}"
					return res.body
				when Net::HTTPNotFound
					raise "No such host is known"
				else
					##Rails.#Rails.##Rails.logger.debug "ERROR HTTP #{res.error}"
					##Rails.##Rails.logger.debug "Respuesta Errada : #{res}"
					raise res.error!
				end  
			rescue Exception => t
				##Rails.#Rails.##Rails.logger.debug "Excepcion Get #{t}"
				##Rails.##Rails.logger.debug "Respuesta Errada CATCH : #{res}"
				raise t
			end
	end
		
end
