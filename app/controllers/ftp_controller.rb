# -*- encoding : utf-8 -*-
require 'net/ftp'

class FtpController < ApplicationController
	before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
	layout 'autenticado.html.haml'
	def index
		@ftp = Ftp.all.first

	end

	def editar_ftp
		if params[:host].present? && params[:puerto].present? && params[:usuario].present? && params[:clave].present? && params[:path].present?

			host = params[:host]
			puerto = params[:puerto]
			usuario = params[:usuario]
			clave = params[:clave]
			path = params[:path]

			begin
				ftp = conectar(host,puerto,usuario,clave,path)  
			rescue Exception => e
				flash[:error] = "Error cambiando el FTP #{e}"
				redirect_to :action => "index"
				return  
			end
			
			begin
				subirPrueba(ftp)
				bajarPrueba(ftp)
			rescue Exception => e
				flash[:error] = "Error cambiando el FTP #{e}"
				redirect_to :action => "index"
				ftp.close
				return
			end

			
			
			ftpp = Ftp.all.first
			if !ftpp.present?
				ftpp = Ftp.new
			end
			ftpp.host = host
			ftpp.puerto = puerto
			ftpp.usuario = usuario
			ftpp.clave = clave
			ftpp.path = path
			ftpp.save

			ftp.close
			camaras_sinftp = setearFtps()
			if camaras_sinftp.count>0
				flash[:error] = "Hubo errores al establecer el FTP en las cámaras #{camaras_sinftp.join('-')}, debe intentarlo nuevamente más tarde."
			else
				
				flash[:exito] = "Cambio de FTP exitoso"

			end
			bitacora "Cambio de FTP con #{host}::#{puerto} usuario: #{usuario} clave: #{clave} path: #{path}"
			redirect_to :action => "index"
			return

		else
			flash[:error] = "Error cambiando el FTP4 #{e}"
			redirect_to :action => "index"
			return
		end

	end
	def subirPrueba(ftp=nil)
		if !ftp.present?
			begin
				ftp = conectar
			rescue Exception => e
				raise "#{e}"
			end
		end
		
		if !File.exists?("prueba.txt")
			File.open('prueba.txt', 'w') do |f2|  
				f2.write "Prueba FTP"
			end
		end
		begin
			
			ftp.putbinaryfile("prueba.txt")
		rescue Exception => e
			raise "Error subiendo el archivo FTP #{e}"
		end
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

	def bajarPrueba(ftp=nil)
		if !ftp.present?
			begin
				ftp = conectar
			rescue Exception => e
				raise "#{e}"
			end
		end
		if archivoExiste(ftp,"prueba.txt")
			ftp.getbinaryfile("prueba.txt","prueba.txt")
		else
			raise "Archivo no encontrado"
		end

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
					Rails.logger.debug "CAMBIANDO LA CARPETA #{carpeta}"
					ftp.chdir(carpeta)

				rescue Net::FTPPermError, NameError => boom # it doesn't exist => create
					Rails.logger.debug "CREANDO LA CARPETA #{carpeta}"
					ftp.mkdir(carpeta)
				end


			end
			ftp.chdir(directorio)
		rescue Exception => e
			raise "#{e}"
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

	def setearFtps
		arreglo = Array.new
		ftp = Ftp.all.first
		errores =false
		camaras = Camara.all
		camaras.each do |camara|
			resultado = setFtp(ftp,camara.ip)
			logger.debug "SETANDO FTP #{camara.ip} #{resultado}"
			if !resultado
				arreglo.push(camara.ip)
			end
		end

		return arreglo
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
	def setFtp(ftp,ipCamara)

		modelo = Camara.ipToModel(ipCamara)
		camara = Camara.ipToCamara(ipCamara)
		getFile(modelo.objeto)
		script = modelo.objeto.constantize
		c = script.new(camara.ip, camara.usuario, camara.contrasena)

		if ftp.path[-1,1]!="/"
			ftp.path+="/"
			ftp.save
		end
		if ftp.path[0,1]!="/"
			ftp.path="/#{ftp.path}"
			ftp.save
		end
		if ftp.path[-1,1]!="/"
			ruta = "#{ftp.path}/#{camara.id}/"
		else
			ruta = "#{ftp.path}#{camara.id}/"
		end
		begin
			
			crearDir("#{ruta}")
		rescue Exception => e
			logger.debug "#{e}"
			return
		end

		begin
			
			respuesta2 = c.setFtp(ftp.host,ftp.puerto,ftp.usuario,ftp.clave,ruta)
		rescue Exception => e
			logger.debug "EL ERROR SETEANDO FTP #{e}"
			if e.message.include? "undefined method"
				return true
			end
			if e.message.include? "unexpected return"
				return true
			end
			return false
		end
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
