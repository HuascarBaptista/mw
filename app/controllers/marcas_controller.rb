# -*- encoding : utf-8 -*-
class MarcasController < ApplicationController
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
  layout 'autenticado.html.haml'
  def index
    @marcas = Marca.all
  end

  def eliminar_marca
  	id_marca = params[:id]

  	@marca=Marca.where(:id=>id_marca).first
  	#@modelo=Modelo.where(:marca_id=>id_marca)
  	logger.debug "-------------------------------------HOLA marca  -> #{@marca}"
  	#logger.debug "-------------------------------------HOLA marca  -> #{@modelo}"

    unless @marca
      flash[:error]="No existe el fabricante"
      redirect_to :action => "eliminar_camara"
      return

    end

    @modelos=Modelo.select(:id).where(:marca_id=>id_marca).map {|i| i.id }

    logger.debug "-------------------------------------AQUI modelos encontrados: #{@modelos}"
    logger.debug "-------------------------------------AQUI id_marca: #{id_marca}"
    

    unless @modelos.empty?
      flash[:error]="Hay modelos asociados a este fabricante, elimínelos primero"
      redirect_to :action => "index" ,:controller => "marcas", :id => id_marca
      return
    end
    aux=@marca.nombre
    @marca.delete
    
    bitacora "EL usuario #{session[:usuario].descripcion} eliminó la marca: #{aux}"

    redirect_to :action => "index"
    flash[:exito]="Fabricante eliminado"
    return
  end

  def ver_modelos
  	@id_marca= params[:id]
  	@modelos=Modelo.where(:marca_id=>@id_marca)

    #Camaras.where("id in (?) ",@camaras_usuario)
  	logger.debug "------------------------------------- modelos  -> #{@modelos}"
    logger.debug "------------------------------------- id_marca  -> #{@id_marca}"
  	
  end
  #Se busca en el directorio de controladores los archivos a mostrar al usuario
  def editar_modelo
    @id_marca=params[:id]
    @id_modelo=params[:modeloId]
    @modelo=Modelo.where(:id=>@id_modelo).first
    @marca=Marca.where(:id=>@id_marca).first
    @controladores = {}
    Dir[File.dirname(__FILE__) +"/../models/controladores/*.rb"].each do |file| 
        begin
          controlador = File.basename( file, ".*" )
          @controladores[controlador]=controlador
        rescue Exception => err
        end
      end
    
    
    
  end
  #Se edita un modelo, y se verifica que los campos recibidos son validos (alto_maximo debe ser  minimo 100)
  def cambiar_modelo
    id_modelo=params[:modeloId]
    id_marca=params[:marcaId]
    nombre= params[:nombre]
    aux=Modelo.where(:nombre=>nombre).first
    modelo=Modelo.where(:id=>id_modelo).first
    modelo.deteccion_movimiento = params[:deteccion_movimiento]
    modelo.rotacion = params[:rotacion] 
    modelo.objeto = params[:objeto]
    modelo.nombre = params[:nombre]

    modelo.ancho_maximo = params[:ancho_maximo]
    modelo.alto_maximo = params[:alto_maximo]

    if modelo.ancho_maximo.to_i <100 
      modelo.ancho_maximo = 100
    end

    if modelo.alto_maximo.to_i <100 
      modelo.alto_maximo = 100
    end

    if modelo.save
      bitacora "El usuario #{session[:usuario].descripcion} cambió el modelo #{modelo.id} llamado #{modelo.nombre}"
      flash[:exito]="Modelo cambiado con éxito"

      logger.debug "El usuario #{session[:usuario].descripcion} cambió el modelo #{modelo.id} llamado #{modelo.nombre}"
      redirect_to :action => "ver_modelos", :id => id_marca

    else
      logger.debug "Error cambiando el modelo"
      flash[:error]="Error cambiando el modelo"
      redirect_to :action => "ver_modelos", :id => id_marca
      
    end
      
    return
  end

  

  def agregar_modelo
    @id_marca=params[:id]
    @marca=Marca.where(:id=>@id_marca).first
    @controladores = {}
    Dir[File.dirname(__FILE__) +"/../models/controladores/*.rb"].each do |file| 
        begin
          controlador = File.basename( file, ".*" )
          @controladores[controlador]=controlador
        rescue Exception => err
        end
      end
  end

  def agregar_modelo_def
    id_marca=params[:marcaId]
    nombre=params[:nombre]
    objeto=params[:objeto]
    unless nombre || objeto
      flash[:error]="No se indicó el nombre del modelo o su controlador"
      redirect_to :action => "index"
      return
    end
    marca=Marca.where(:id=>id_marca).first
    @modelos=Modelo.select(:nombre).where(:marca_id=>id_marca).map {|i| i.nombre }

    logger.debug "-------------------------------------AQUI Modelo encontrados: #{@modelos}"

    if @modelos.include? nombre
      
      flash[:error]="#{marca.nombre} ya tiene ese modelo registrado"
      redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
      return
    end
    modelo = Modelo.new
    modelo.marca_id = id_marca
    modelo.deteccion_movimiento = params[:deteccion_movimiento]
    modelo.rotacion = params[:rotacion] 
    modelo.objeto = params[:objeto]
    modelo.nombre = params[:nombre]

    modelo.ancho_maximo = params[:ancho_maximo]
    modelo.alto_maximo = params[:alto_maximo]

    if modelo.ancho_maximo<100 
      modelo.ancho_maximo = 100
    end

    if modelo.alto_maximo<100 
      modelo.alto_maximo = 100
    end

    if modelo.save
      bitacora "EL usuario #{session[:usuario].descripcion} agregó el modelo #{modelo.nombre} de #{marca.nombre}"
      flash[:exito]="Modelo agregado con éxito"
      redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
      return
    else
      bitacora "EL usuario #{session[:usuario].descripcion} falló al agregar el modelo #{modelo.nombre} de #{marca.nombre}"
      flash[:error]="Error agregando el modelo"
      redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
      return
    end
    
  end

  

  def eliminar_modelo
    id_marca=params[:marcaId]
    id_modelo=params[:modeloId]
    modelo=Modelo.where(:id=>id_modelo).first


    @camaras=Camara.select(:ip).where(:modelo_id=>id_modelo).map {|i| i.ip }
    #@camaras=Camara.where(:modelo_id=>id_modelo)

    logger.debug "-------------------------------------AQUI Camaras encontrados: #{@camaras}"
    

    unless @camaras.empty?
      flash[:error]="Hay cámaras registradas con ese modelo"
      redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
      return
    end

    unless modelo 
      flash[:error]="Modelo no encontrado"
      redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
      return
    end

    @camaras=Camara.where(:modelo_id=>:id_modelo)
    modelo.delete
    flash[:exito]="Se eliminó el modelo #{modelo.nombre}"
    redirect_to :action => "ver_modelos" ,:controller => "marcas", :id => id_marca
    return

  	
  end

  def agregar_marca
  	
  end

  def agregar_marca_def
    #datas = params[:frmOptions]
    
    logger.debug "------------------------------------- HOLA"
    #logger.debug "------------------------------------- marca  -> #{count}"
    #aux = params[:form-agregarMarca][:nombre]
    nombre=params[:nombre]
  	logger.debug "------------------------------------- marca  -> #{nombre}"
  	unless nombre
  		flash[:error]="No se indicó el fabricante"
	    redirect_to :action => "agregar_marca"
	    return

  		
  	end

    aux= Marca.where(:nombre=>nombre).first
    unless aux
      marca = Marca.new
      marca.nombre = nombre
      marca.save
      flash[:exito]="Fabricante agregado con éxito"
      redirect_to :action => "index" ,:controller => "marcas"
      return
    end
  	flash[:error]="Ya existe ese fabricante"
    redirect_to :action => "index" ,:controller => "marcas"
    
    return
  	
  end
  def editar_marca_def
    #datas = params[:frmOptions]
    
    id=params[:valor]
    nombre = params[:nombre]
    @marca = Marca.where(:id=>id).first
    unless @marca
      flash[:error]="No se indicó el fabricante"
      redirect_to :action => "editar_marca"
      return
    end
    @marca.nombre = nombre
    @marca.save
    aux= Marca.where(:nombre=>nombre).first
     flash[:exito]="Fabricante editado con éxito"
      redirect_to :action => "index" ,:controller => "marcas"
      return
    
  end
  def editar_marca
    #datas = params[:frmOptions]
    
    id=params[:id]
    @marca = Marca.where(:id=>id).first
    unless @marca
      flash[:error]="No se indicó el fabricante"
      redirect_to :action => "index"
      return
    end
    
  end

end
