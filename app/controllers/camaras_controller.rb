# -*- encoding : utf-8 -*-
class CamarasController < ApplicationController
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
  layout 'autenticado.html.haml'
  def index
    @camaras = Camara.all
    
  end

  def eliminar_camara
  	id=params[:id]

  	camara=Camara.where(:id=>id).first

  	logger.debug "-------------------------------------AQUI ID: #{id}"

  	logger.debug "-------------------------------------AQUI Camaras encontradas: #{camara}"

  	unless camara
  		flash[:error]="No se encontró la cámara"
			redirect_to :action => "index" 
			return
  	end


  	if camara.delete
      bitacora "EL usuario #{session[:usuario].descripcion} eliminó la cámara: #{camara.id} con IP #{camara.ip}"
		  flash[:exito]="Se eliminó la cámara"
		  redirect_to :action => "index" 
		  return
    end
    bitacora "EL usuario #{session[:usuario].descripcion} no pudo eliminar la cámara: #{camara.id} con IP #{camara.ip}"
    flash[:error]="Error eliminando la cámara"
    redirect_to :action => "index" 
    return
  	
  end

  def camaras_asociadas
    id_modelo=params[:modeloId]

    @id_marca=params[:marcaId]
    @modelo = Modelo.where(:id=>id_modelo).first
    @marca = Marca.where(:id=>@id_marca).first
    @camaras=Camara.where(:modelo_id=>id_modelo)
    logger.debug "-------------------------------------AQUI camaras_asociadas: #{@camaras}"

  end

  def ver_camara
    id_camara=params[:id]
    @camara=Camara.where(:id=>id_camara).first
    
  end

  def guardar_editar_camara
    id=params[:camaraId]
    camara = Camara.where(:id=>id).first
    
      unless camara
        flash[:error] =  "Error cámara no existe"
        redirect_to :back
        return
      end
      modelo= camara.modelos

      unless modelo
        flash[:error] =  "Error el modelo no existe"
        redirect_to :back
        return
      end

      

      script = modelo.objeto.constantize
      c = script.new(camara.ip, camara.usuario, camara.contrasena)
      respuesta = c.setAutentication(params[:ip],params[:puerto],params[:usuario],params[:contrasena])

     if respuesta.present? && respuesta =="success"
        camara.ip=params[:ip]
        camara.autorotacion=params[:autorotacion]
        camara.puerto=params[:puerto]
        camara.usuario=params[:usuario]
        camara.contrasena=params[:contrasena]
        camara.fecha_registro=params[:fechaRegistro]
        camara.deteccion_movimiento=params[:deteccion]
        camara.defectuosa=params[:defectuosa]

        if camara.save
          bitacora "EL usuario #{session[:usuario].descripcion} modificó la cámara: #{camara.id} con IP #{camara.ip}"
          flash[:exito]="Cámara modificada exitosamente"
          redirect_to :action => "index" ,:controller => "camaras"
          return
        else
          bitacora "EL usuario #{session[:usuario].descripcion} no pudo moficar la cámara: #{camara.id} con IP #{camara.ip}"
          flash[:error]="Error modificando la cámara #{camara.errors.full_messages}" 
          redirect_to :action => "index" ,:controller => "camaras"
          return
        end
      else
        bitacora "EL usuario #{session[:usuario].descripcion} no pudo moficar la cámara: #{camara.id} con IP #{camara.ip}"
        flash[:error]="Error modificando la cámara #{camara.errors.full_messages}" 
        redirect_to :action => "index" ,:controller => "camaras"
        return
      end


    
  end

  def agregar_camara_marca
    @marcas=Marca.all
    
  end

  def agregar_camara
    @id_marca=params[:marca]
    @id_modelo=params[:modelo]


    @modelo=Modelo.where(:id=>@id_modelo).first

    logger.debug "-------------------------***//**------AQUI modelo #{@nombre}"
    logger.debug "-------------------------***//**------AQUI marca: #{@id_marca}"
  end

  def guardar_nueva_camara
    id_marca=params[:marcaId]
    id_modelo=params[:modeloId]
    @modelo=Modelo.where(:id=>id_modelo).first
    ip=params[:ip]
    autorotacion=params[:autorotacion]
    calidad_foto=params[:calidadFoto]
    puerto=params[:puerto]
    usuario=params[:usuario]
    contrasena=params[:contrasena]
    fecha_registro=params[:fechaRegistro]
    deteccion_movimiento=params[:deteccion]
    camara=Camara.where(:ip=>ip).first

    unless camara

      camara = Camara.new
      camara.modelo_id = id_modelo
      camara.ip = ip
      camara.autorotacion = autorotacion
      camara.puerto = puerto
      camara.usuario = usuario
      camara.contrasena = contrasena
      camara.deteccion_movimiento = deteccion_movimiento
      camara.save
      flash[:exito]="Cámara guardada con éxito"
      redirect_to :action => "index" ,:controller => "camaras"
      return
      
    else
      flash[:error]="Ya está registrada esa dirección IP"
      redirect_to :back 
      return
    end

    
  end

  

  def ajax_modelo_camara
    
    marca = params[:marca]
    if(marca!="")

      #response = Mw.get_modelos(marca)
      @modelos =  Modelo.where(:marca_id=>marca)
      logger.debug "-------------------------***//**------AQUI modelos: #{@modelos}"
      #=Bitacora.where(:usuario => usuario)
    end
    render :layout =>false
  end

  

end
