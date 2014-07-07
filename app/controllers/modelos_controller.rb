# -*- encoding : utf-8 -*-
class ModelosController < ApplicationController
  before_filter :verificar_autenticado # antes de ejecutar algo de este controlador cualquier cosa voy correr esto
  layout 'autenticado.html.haml'
  def index
    @modelos = Modelo.all
    @marcas = Marca.all
  end

  

end
