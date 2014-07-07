# -*- encoding : utf-8 -*-
require "base64"
require "uri"
require "socket"
require "net/http"
require "cgi"
require 'net/ftp'

class TesisController < ApplicationController
	# Esta linea de codigo valida que el usuario que esta 
	# ingresando tiene los permisos necesarios para la aplicacion
	before_filter :validar
	#Esta linea de codigo permite que estas acciones sean accedidas desde otra ip que no sea la del servidor
	protect_from_forgery :except => [:agregarCamara,:obtenerCamara,:obtenerImagen,:moverCamara,:autenticacionCamara,:setFtp,
		:getInformacionModelo,:getInformacionMarca,:getMarcas,:getModelos]
	include HTTParty
	@server_id = nil
	@server_key = nil
	@ip = nil
	#Esta accion se usa para devolver el server_key y server_id del cliente que lo solicita
	def getServerKey
		msg = { :status => "success", :server_id => @server_id, :server_key => @server_key}
		render :json => msg
		return
	end
	def getFile(nombre)

		Dir[File.dirname(__FILE__) +"/../models/controladores/#{nombre}.rb"].each do |file| 
			begin
				Rails.logger.debug "EL ARCHIVO #{file}"
				require file
			rescue Exception => err
				Rails.logger.debug "EL EERROOR ARCHIVO #{err}"
			end
		end
	end
	#Retorna las marcas que se tienen en la base de datos
	def getMarcas
		marcas=Marca.select("nombre,id")
		msg = { :status => "success", :marcas => marcas }
		render :json => msg
		return  
	end
	#Retorna los modelos que se tienen en la base de datos segun una marca en especifico
	def getInformacionModelo
		modelo = params[:modelo].to_i
		if modelo
			modelo = Modelo.where(:id=>modelo).first
			msg = { :status => "success", :modelos => modelo }
			render :json => msg
		else
			msg = { :status => "error", :message => "Error modelo invalido"}
			render :json => msg
		end
		return  
	end
	def getInformacionMarca
		marca = params[:marca].to_i
		if marca
			marca = Marca.where(:id=>marca).first
			msg = { :status => "success", :marca => marca }
			render :json => msg
		else
			msg = { :status => "error", :message => "Error marca invalida"}
			render :json => msg
		end
		return  
	end
	#Retorna los modelos que se tienen en la base de datos segun una marca en especifico
	def getModelos
		marca = params[:marca].to_i
		if marca
			marca = Marca.where(:id=>marca).first
			if marca
				modelos = Modelo.select("nombre,id").where(:marca_id=>marca.id.to_i)
				msg = { :status => "success", :modelos => modelos }
				render :json => msg
			else
				msg = { :status => "error", :message => "Error marca invalida"}
				render :json => msg
			end
		else
			msg = { :status => "error", :message => "Error marca invalida"}
			render :json => msg
		end
		return  
	end
	# Esta funcion valida que el usuario que quiere acceder a la camara tiene los permisos necesarios
	# y se encarga de solicitarle una imagen a la cámara y enviarla en forma de string
	def obtenerImagen
		ip = params[:ipCamara]
		camara=Camara.where(:ip=>ip).first
		unless camara 
			msg = { :status => "error", :message => "Error cámara invalida"}
			render :json => msg
			return
		end
		validando = AutenticacionCamara.where(:autenticacion_id=>session[:id_autenticacion],:camara_id=>camara.id).first
		unless validando
			msg = { :status => "error", :message => "No tienes permiso a esta cámara"}
			render :json => msg
			return
		else
			modelo = Camara.ipToModel(ip)
			if modelo
				getFile(modelo.objeto)
				script = modelo.objeto.constantize
				begin
					c = script.new(camara.ip, camara.usuario, camara.contrasena)
				rescue Errno::ETIMEDOUT  => e
					msg = { :status => "error", :message =>"Cámara inalcanzable"}
					render :json => msg
					return
				rescue Exception => t
					
					if t.message.include? "No such host is known"
						msg = { :status => "error", :message =>"Cámara inalcanzable"}
						render :json => msg
						return
					end
					
					msg = { :status => "error", :message =>"Mala autenticación"}
					render :json => msg
					return
				end
				foto = c.obtenerImagen
			else
				msg = { :status => "error", :message => "Error cámara invalida"}
				render :json => msg
				return
			end

			if foto == "camara"
				msg = { :status => "error", :message =>"Cámara inalcanzable"}
				render :json => msg
				return
			elsif foto=="autenticacion"
				msg = { :status => "error", :message =>"Mala autenticación"}
				render :json => msg
				return
			elsif foto=="foto"
				msg = { :status => "error", :message =>"Foto dañada"}
				render :json => msg
				return
			elsif foto =="No connection could be made because the target machine actively refused it"

				contador = 0

				foto = c.obtenerImagen

				while (foto== "No connection could be made because the target machine actively refused it" || foto== "camara"  && contador < 2) || contador == 0

					if foto.include? "autenticacion"
						msg = { :status => "error", :message =>"Mala autenticación"}
						render :json => msg
						return
					elsif foto.include? "foto"
						msg = { :status => "error", :message =>"Foto dañada"}
						render :json => msg
						return
					end
					sleep 1
					foto = c.obtenerImagen
					contador=contador+1
				end

				if foto.include? "camara"
					msg = { :status => "error", :message =>"Cámara inalcanzable"}
					render :json => msg
					return
				elsif foto.include? "autenticacion"
					msg = { :status => "error", :message =>"Mala autenticación"}
					render :json => msg
					return
				elsif foto.include? "foto"
					msg = { :status => "error", :message =>"Foto dañada"}
					render :json => msg
					return

				elsif foto.include? "No connection could be made because the target machine actively refused it"
					msg = { :status => "error", :message =>"La cámara está ocupada por favor intente de nuevo."}
					render :json => msg
					return

				end

				
			end

			
			msg = { :status => "success", :message => foto}
			render :json => msg
			return
		end
	end

	def obtenerCamara
		ip = params[:ipCamara]
		camara=Camara.where(:ip=>ip).first
		Rails.logger.debug "MODELO #{camara.modelos}"
		unless camara 
			msg = { :status => "error", :message => "Error cámara invalida"}
			render :json => msg
			return
		end
		validando = AutenticacionCamara.where(:autenticacion_id=>session[:id_autenticacion],:camara_id=>camara.id).first
		unless validando
			msg = { :status => "error", :message => "No tienes permiso a esta cámara"}
			render :json => msg
			return
		else
			msg = { :status => "success", :message => camara, :modelo => camara.modelos }
			render :json => msg
			return
		end
	end
	def getInfoGeneral
		modelo = Camara.ipToModel(params[:ipCamara])
		if modelo
			camara = Camara.ipToCamara(params[:ipCamara])
			if !camara
				msg = { :status => "error", :message => "Error cámara invalida"}
				render :json => msg
				return
			end

			getFile(modelo.objeto)
			script = modelo.objeto.constantize
			begin
							c = script.new(camara.ip, camara.usuario, camara.contrasena)
						rescue Errno::ETIMEDOUT  => e
							msg = { :status => "error", :message =>"Cámara inalcanzable"}
							render :json => msg
							return
						rescue Exception => t
							
							if t.message.include? "No such host is known"
								msg = { :status => "error", :message =>"Cámara inalcanzable"}
								render :json => msg
								return
							end
							
							msg = { :status => "error", :message =>"Mala autenticación"}
							render :json => msg
							return
						end
			logger.debug "El objeto  #{c}"
			c.getInfoGeneral

		else
			msg = { :status => "error", :message => "Error cámara invalida"}
			render :json => msg
			return
		end
	end

	def moverCamara
		modelo = Camara.ipToModel(params[:ipCamara])
		if modelo
			camara = Camara.ipToCamara(params[:ipCamara])
			if !camara
				msg = { :status => "error", :message => "Error cámara invalida"}
				render :json => msg
				return
			end

			getFile(modelo.objeto)
			script = modelo.objeto.constantize
			begin
				c = script.new(camara.ip, camara.usuario, camara.contrasena)
			rescue Errno::ETIMEDOUT  => e
				msg = { :status => "error", :message =>"Cámara inalcanzable"}
				render :json => msg
				return
			rescue Exception => t
				
				if t.message.include? "No such host is known"
					msg = { :status => "error", :message =>"Cámara inalcanzable"}
					render :json => msg
					return
				end
				
				msg = { :status => "error", :message =>"Mala autenticación"}
				render :json => msg
				return
			end
			logger.debug "El objeto  #{c}"

			respuesta = c.moverCamara(params[:direccion])

			if respuesta.present? && respuesta =="success"
				msg = { :status => "success", :message => "Cámara modificada con exito"}
				render :json => msg
				return
			else
				if respuesta == "camara"
					msg = { :status => "error", :message =>"Cámara inalcanzable"}
					render :json => msg
					return
				elsif respuesta=="autenticacion"
					msg = { :status => "error", :message =>"Mala autenticación"}
					render :json => msg
					return
				elsif respuesta==nil
					msg = { :status => "error", :message =>"Error modificando la cámara"}
					render :json => msg
					return
				end
				msg = { :status => "error", :message => "Error modificando la camara"}
				render :json => msg
				return
			end

		else
			msg = { :status => "error", :message => "Error cámara invalida"}
			render :json => msg
			return
		end
		
	end

	
	def autenticacionCamara

		modelo= Camara.ipToModel(params[:ipCamaraViejo])
		camara = Camara.ipToCamara(params[:ipCamaraViejo])

		validando = AutenticacionCamara.where(:autenticacion_id=>session[:id_autenticacion],:camara_id=>camara.id).first
		unless validando
			msg = { :status => "error", :message => "No tienes permiso a esta cámara"}
			render :json => msg
			return
		end
		
		unless modelo
			msg = { :status => "error", :message => "Error el modelo no existe"}
			render :json => msg
			return
		end
		id_modelo =modelo.id
		unless camara
			msg = { :status => "error", :message => "Error cámara no existe"}
			render :json => msg
			return
		end
		getFile(modelo.objeto)
		script = modelo.objeto.constantize
		begin
			c = script.new(camara.ip, camara.usuario, camara.contrasena)
		rescue Errno::ETIMEDOUT  => e
			msg = { :status => "error", :message =>"Cámara inalcanzable"}
			render :json => msg
			return
		rescue Exception => t
			
			if t.message.include? "No such host is known"
				msg = { :status => "error", :message =>"Cámara inalcanzable"}
				render :json => msg
				return
			end
			
			msg = { :status => "error", :message =>"Mala autenticación"}
			render :json => msg
			return
		end
		logger.debug "El objeto  #{c}"
		
		camara.ip = params[:ipCamara]
		camara.usuario = params[:usuario]
		camara.contrasena = params[:contrasena]
		camara.puerto = params[:puerto]
		camara.save
		msg = { :status => "success", :message => "Cámara modificada con exito"}
		render :json => msg
		return

	end
	def sanitize_filename(filename)
   		filename = "#{filename}"
     	filename.gsub(/[^0-9A-z.\-]/, '_')
   	end
	def agregarCamara
		begin
			if params[:modelo].present?
				id_modelo=params[:modelo]
				@modelo=Modelo.where(:id=>id_modelo).first
			else
				@modelo= Camara.ipToModel(params[:ipCamara])
				@camm = Camara.ipToCamara(params[:ipCamara])
				id_modelo =@modelo.id
				params[:usuario] = @camm.usuario
				params[:contrasena] = @camm.contrasena
			end
			
			unless @modelo
				msg = { :status => "error", :message => "Error el modelo no existe"}
				render :json => msg
				return
			end
			id_marca = @modelo.marca.id
			#establezco parametros
			if !params[:puerto].present?
				puerto = "80"
			else
				puerto=params[:puerto]
			end
			if !params[:usuario].present?
				usuario = ""
			else
				usuario=params[:usuario]
			end
			if !params[:contrasena].present?
				contrasena = ""
			else
				contrasena=params[:contrasena]
			end
			
			if !params[:valSensibilidad].present?
				val_sensibilidad = 0
			else
				val_sensibilidad=params[:valSensibilidad]
			end
			if !params[:valPorcentaje].present?
				val_porcentaje = 0
			else
				val_porcentaje=params[:valPorcentaje]
			end
			if !params[:valPorcentaje].present?
				val_porcentaje = 0
			else
				val_porcentaje=params[:valPorcentaje]
			end
			if !params[:intervalo_captura].present?
				intervalo_captura = 0
			else
				intervalo_captura=params[:intervalo_captura]
			end
			if !params[:horas].present?
				horas = 0
			else
				horas=params[:horas]
			end
			if !params[:minutos].present?
				minutos = 0
			else
				minutos=params[:minutos]
			end
			if !params[:segundos].present?
				segundos = 0
			else
				segundos=params[:segundos]
			end
			logger.debug "CONO #{params[:deteccionMovimiento]} presente? #{params[:deteccionMovimiento].present?}"
			if !params[:deteccionMovimiento].present?
				deteccion_movimiento = 0
			else
				deteccion_movimiento=params[:deteccionMovimiento]
			end
			if !params[:dm_x].present?
				dm_x = 0
			else
				dm_x=params[:dm_x]
			end
			if !params[:dm_y].present?
				dm_y = 0
			else
				dm_y=params[:dm_y]
			end
			if !params[:dm_an].present?
				dm_an = 0
			else
				dm_an=params[:dm_an]
			end
			if !params[:dm_al].present?
				dm_al = 0
			else
				dm_al=params[:dm_al]
			end
			logger.debug "QUEDO EN #{deteccion_movimiento} presente? #{deteccion_movimiento.present?}"
			#Compruebo si la camara existia
			ip=params[:ipCamara]
			camara=Camara.where(:ip=>ip).first
			unless camara
				#No existe la camara entonces la guardo y se la asigno a este id
				camara = Camara.new
				camara.intervalo_captura = intervalo_captura
				camara.val_sensibilidad=val_sensibilidad
				camara.val_porcentaje=val_porcentaje
				camara.horas = horas
				camara.minutos = minutos
				camara.segundos = segundos
				camara.ip = ip
				camara.usuario = usuario
				camara.contrasena = contrasena
				camara.deteccion_movimiento=deteccion_movimiento
				camara.dm_x = dm_x
				camara.dm_y = dm_y
				camara.dm_an = dm_an
				camara.dm_al = dm_al

				camara.modelo_id = @modelo.id
				if camara.save
					autenticacionCamara = AutenticacionCamara.new
					autenticacionCamara.camara_id = camara.id
					autenticacionCamara.autenticacion_id = session[:id_autenticacion]
					autenticacionCamara.save


					#Asigno IP y tamano de la imagen y calidad
					modelo= Camara.ipToModel(camara.ip)
					id_modelo =modelo.id
					unless camara
						msg = { :status => "error", :message => "Error cámara no existe"}
						render :json => msg
						return
					end
					getFile(modelo.objeto)
					script = modelo.objeto.constantize

					begin
						c = script.new(camara.ip, camara.usuario, camara.contrasena)
					rescue Errno::ETIMEDOUT  => e
						camara.delete
						msg = { :status => "error", :message =>"Cámara inalcanzable"}
						render :json => msg
						return
					rescue Exception => t
						camara.delete
						if t.message.include? "No such host is known"
							msg = { :status => "error", :message =>"Cámara inalcanzable"}
							render :json => msg
							return
						end
						
						msg = { :status => "error", :message =>"Mala autenticación"}
						render :json => msg
						return
					end

					respuesta1 = c.setTamano
					if respuesta1 == "camara"
						camara.delete
						msg = { :status => "error", :message =>"Cámara inalcanzable"}
						render :json => msg
						return
					elsif respuesta1=="autenticacion"
						camara.delete
						msg = { :status => "error", :message =>"Mala autenticación"}
						render :json => msg
						return
					elsif respuesta1==nil
						camara.delete
						msg = { :status => "error", :message =>"Error en la transaccion"}
						render :json => msg
						return
					end

					errores = ""

					if Ftp.all.first.present?
						if !setFtp(Ftp.all.first,camara.ip)
							errores +="Error seteando FTP"
							logger.debug "Error seteando FTP"
						end
					else
						errores +="No hay FTP definido"
					end


					logger.debug "camara.deteccion_movimiento.present? #{camara.deteccion_movimiento.present?}"
					logger.debug "camara.deteccion_movimiento=='1' #{camara.deteccion_movimiento=="1"}"
					logger.debug "camara.deteccion_movimiento #{camara.deteccion_movimiento}"

					msg = { :status => "success", :message => "true",:otrosErrores=>errores}
					render :json => msg
					return
				else
					msg = { :status => "error", :message => "Error guardando en base de datos",:otrosErrores=>errores}
					render :json => msg
					return
				end
			else
				#Existe la camara, compruebo si tiene el mismo modelo
				if @modelo.id != camara.modelo_id
					msg = { :status => "error", :message => "IP asignada a otro modelo de cámara"}
					render :json => msg
					return
				end

				#Existe la camara, compruebo si tiene el mismo usuario y contraseña
				logger.debug "PUERTO q tngo #{camara.puerto} y el que viene #{puerto} "
				logger.debug "usuario q tngo #{camara.usuario} y el que viene #{usuario} "
				logger.debug "contrasena q tngo #{camara.contrasena} y el que viene #{contrasena} "

				logger.debug "puerto comprobando #{puerto == camara.puerto} "

				logger.debug "usuario comprobando #{usuario == camara.usuario} "

				logger.debug "contrasena comprobando #{contrasena == camara.contrasena} "

				logger.debug "Los tres comprobando #{puerto == camara.puerto && usuario == camara.usuario && contrasena == camara.contrasena} "


				if puerto == camara.puerto && usuario == camara.usuario && contrasena == camara.contrasena
					logger.debug "Debo guardar la nueva configuracion de la camara, estableciendo tiempos minimos"
					#Debo guardar la nueva configuracion de la camara, estableciendo tiempos minimos
					if deteccion_movimiento !="0" 

						camara.val_sensibilidad=val_sensibilidad
						camara.val_porcentaje=val_porcentaje
						camara.deteccion_movimiento=deteccion_movimiento
						camara.dm_x = dm_x
						camara.dm_y = dm_y
						camara.dm_an = dm_an
						camara.dm_al = dm_al
					end
					logger.debug "Estoy mandando a que tome fotos por tiempos"
					#Estoy mandando a que tome fotos por tiempos
					if intervalo_captura != false
						#Antes no tomaba fotos por tiempo por lo que establezo ahora eso
						if camara.intervalo_captura==0
							camara.horas = horas
							camara.minutos = minutos
							camara.segundos = segundos
						else
							#Antes tomaba fotos por tiempo por lo que establezo el minimo de ellos 
							camara.horas = [camara.horas,horas].min
							camara.minutos = [camara.minutos,minutos].min
							camara.segundos = [camara.segundos,segundos].min
						end
					end
					logger.debug "Save "
					if camara.save
						validando = AutenticacionCamara.where(:autenticacion_id=>session[:id_autenticacion],:camara_id=>camara.id).first
						unless validando
							autenticacionCamara = AutenticacionCamara.new
							autenticacionCamara.camara_id = camara.id
							autenticacionCamara.autenticacion_id = session[:id_autenticacion]
							autenticacionCamara.save
		
						end
						logger.debug "Seteo tamano de Imagen, FTP, Deteccion Movimiento"
						#Seteo tamano de Imagen, FTP, Deteccion Movimiento
						modelo= Camara.ipToModel(camara.ip)
						id_modelo =modelo.id
						unless camara
							msg = { :status => "error", :message => "Error cámara no existe"}
							render :json => msg
							return
						end
						getFile(modelo.objeto)
						script = modelo.objeto.constantize
						begin
							c = script.new(camara.ip, camara.usuario, camara.contrasena)
						rescue Errno::ETIMEDOUT  => e
							msg = { :status => "error", :message =>"Cámara inalcanzable"}
							render :json => msg
							return
						rescue Exception => t
							
							if t.message.include? "No such host is known"
								msg = { :status => "error", :message =>"Cámara inalcanzable"}
								render :json => msg
								return
							end
							
							msg = { :status => "error", :message =>"Mala autenticación"}
							render :json => msg
							return
						end

						respuesta1 = c.setTamano
						if respuesta1 == "camara"
							msg = { :status => "error", :message =>"Cámara inalcanzable"}
							render :json => msg
							return
						elsif respuesta1=="autenticacion"
							msg = { :status => "error", :message =>"Mala autenticación"}
							render :json => msg
							return
						elsif respuesta1==nil
							msg = { :status => "error", :message =>"Error en la transaccion"}
							render :json => msg
							return
						end

						errores = ""

						if Ftp.all.first.present?
							if !setFtp(Ftp.all.first,camara.ip)
								errores +="Error seteando FTP"
								logger.debug "Error seteando FTP"
							end
						else
							errores +="No hay FTP definido"
						end

						logger.debug "camara.deteccion_movimiento.present? #{camara.deteccion_movimiento.present?}"
						logger.debug "camara.deteccion_movimiento=='1' #{camara.deteccion_movimiento=="1"}"
						logger.debug "camara.deteccion_movimiento #{camara.deteccion_movimiento}"

						if camara.deteccion_movimiento.present? && camara.deteccion_movimiento==true
							respuesta1 = c.deteccionMovimiento("ventana 1 ",camara.dm_x,camara.dm_y,camara.dm_an,camara.dm_al,camara.val_porcentaje,camara.val_sensibilidad)
							if respuesta1 == "camara"
								msg = { :status => "error", :message =>"Cámara inalcanzable",:otrosErrores=>errores}
								render :json => msg
								return
							elsif respuesta1=="autenticacion"
								msg = { :status => "error", :message =>"Mala autenticación",:otrosErrores=>errores}
								render :json => msg
								return
							elsif respuesta1==nil
								msg = { :status => "error", :message =>"Error en la transaccion",:otrosErrores=>errores}
								render :json => msg
								return
							end
						end

						msg = { :status => "success", :message => "true",:otrosErrores=>errores}
						render :json => msg
						return
					else
						msg = { :status => "error", :message => "Error guardando en base de datos",:otrosErrores=>errores}
						render :json => msg
						return
					end

				else
					msg = { :status => "error", :message => "Error usuario y contraseña de la cámara no coinciden"}
					render :json => msg
					return
				end
			end
		rescue 	 => e
			msg = { :status => "error", :message => "Lo sentimos ocurrio un error #{e}"}
			render :json => msg
			return
		end
	end

	def crearDir(ftp=nil,directorio)
		Rails.logger.debug "Creando el directorio #{directorio}"
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
				logger.debug "Carpeta actual #{carpeta}"
				begin
					Rails.logger.debug "Cambiando carpeta #{carpeta}"
					ftp.chdir(carpeta)

				rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
					Rails.logger.debug "Creando carpeta #{carpeta}"
					ftp.mkdir(carpeta)
				end


			end
			ftp.chdir(directorio)
		rescue Exception => e
			raise "#{e}"
		end
		ftp.close
	end
	def conectar(host=nil,puerto=nil,usuario=nil,clave=nil,path=nil)
		if !host.present?
			ftpp = Ftp.all.first
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
						Rails.logger.debug "CAMBIANDO LA CARPETA #{carpeta}"
						ftp.chdir(carpeta)

					rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
						Rails.logger.debug "CREANDO LA CARPETA #{carpeta}"
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
	
	def setFtp(ftpp,ipCamara)

		modelo = Camara.ipToModel(ipCamara)
		camara = Camara.ipToCamara(ipCamara)
		getFile(modelo.objeto)
		script = modelo.objeto.constantize
		begin
							c = script.new(camara.ip, camara.usuario, camara.contrasena)
						rescue Errno::ETIMEDOUT  => e
							msg = { :status => "error", :message =>"Cámara inalcanzable"}
							render :json => msg
							return
						rescue Exception => t
							
							if t.message.include? "No such host is known"
								msg = { :status => "error", :message =>"Cámara inalcanzable"}
								render :json => msg
								return
							end
							
							msg = { :status => "error", :message =>"Mala autenticación"}
							render :json => msg
							return
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
			logger.debug "EL ERROR SETEANDO FTP CREANDO DIR #{e}"
			return false
		end

		begin
			ftp.close
			respuesta2 = c.setFtp(ftpp.host,ftpp.puerto,ftpp.usuario,ftpp.clave,ruta)
		rescue Exception => e
			logger.debug "EL ERROR SETEANDO FTP #{e}"
			if e.message.include? "undefined method"
				return true
			end
			return false
		end
		logger.debug "Seteando FTP  #{respuesta2}"
		#respuesta2 = c.deteccionMovimiento("HaMil","0","0","704","480","10","10")
		if respuesta2 == "camara"
			
			return false
		elsif respuesta2=="autenticacion"
			return false
		elsif respuesta2==nil
			return false
		end

		return true
	end

end
