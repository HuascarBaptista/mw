############################################################################
# demo_daemon_ctl.rb
#
# This is a command line script for installing and/or running a small
# Ruby program as a service.  The service will simply write a small bit
# of text to a file every 20 seconds. It will also write some text to the
# file during the initialization (service_init) step.
#
# It should take about 10 seconds to start, which is intentional - it's a test
# of the service_init hook, so don't be surprised if you see "one moment,
# start pending" about 10 times on the command line.
#
# The file in question is C:\test.log.  Feel free to delete it when finished.
#
# To run the service, you must install it first.
#
# Usage: ruby demo_daemon_ctl.rb <option>
#
# Note that you *must* pass this program an option
#
# Options:
#    install    - Installs the service.  The service name is "DemoSvc"
#                 and the display name is "Demo".
#    start      - Starts the service.  Make sure you stop it at some point or
#                 you will eventually fill up your filesystem!.
#    stop       - Stops the service.
#    pause      - Pauses the service.
#    resume     - Resumes the service.
#    uninstall  - Uninstalls the service.
#    delete     - Same as uninstall.
#
# You can also used the Windows Services GUI to start and stop the service.
#
# To get to the Windows Services GUI just follow:
#    Start -> Control Panel -> Administrative Tools -> Services
############################################################################
require 'rubygems'        # if you use RubyGems
require 'daemons'

demonios=["demonioBuscarFotos.rb","demonioBorrarFotos.rb","demonioComprobarCamara.rb","demonioFotosDeteccion.rb"]

nombresDemonios={"mw_demonioBuscarFotos"=>0,"mw_demonioBorrarFotos"=>1,"mw_demonioComprobarCamara"=>2,
"mw_demonioFotosDeteccion"=>3}

nombres=["mw_demonioBuscarFotos","mw_demonioBorrarFotos","mw_demonioComprobarCamara",
"mw_demonioFotosDeteccion"]

descripcion=["Demonio que trae fotos de cada camara y las distribuye entre los distintos clientes",
"Demonio que borra fotos en el MW que tienen mas de 15 dias de antiguedad",
"Demonio que comprueba que cada camara estre funcionando, notificando el estado de cada una de ellas a sus clientes",
"Demonio que adquiere las fotos servidas por la deteccion de movimiento y se les notifica a los clientes"]

# Quote the full path to deal with possible spaces in the path name.
ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
pathOriginal = ' "' + File.dirname(File.expand_path($0)).tr('/', '\\')

# You must provide at least one argument.
raise ArgumentError, 'No argument provided' unless ARGV[0]

case ARGV[0].downcase
	when 'startall'
		
		for i in 0..3
			begin
			ruta = demonios[i]
			Daemons.run(ruta,options = {:app_name => nombres[i]})
			rescue Exception => e
				puts "Error instalando todos #{e} #{nombres[i]}"
			end
			puts 'Servicio ' +  nombres[i]+ ' iniciado'   
			
		end
		
	when "start"
		begin
			ruta = demonios[nombresDemonios[ARGV[1]]]

			Daemons.run(ruta,options = {:app_name => nombres[nombresDemonios[ARGV[1]]] })

			puts 'Servicio ' + nombres[nombresDemonios[ARGV[1]]] + ' iniciado'     
		rescue Exception => e
			puts "Error iniciando #{e}"
		end 
	when 'stop'
		begin
			if Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'stopped'
				Service.stop(nombres[nombresDemonios[ARGV[1]]])
				while Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'stopped'
					puts 'One moment...' + Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state
					sleep 1
				end
				puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' stopped'
			else
				puts 'Already stopped'
			end

		rescue Exception => e
			puts "Error deteniendo #{e}"
		end
	when 'stopall'
		
		for i in 0..3
			begin 
			if Service.status(nombres[i]).current_state != 'stopped'
				Service.stop(nombres[i])
				while Service.status(nombres[i]).current_state != 'stopped'
					puts 'One moment...' + Service.status(nombres[i]).current_state
					sleep 1
				end
				puts 'Service ' + nombres[i] + ' stopped'
			else
				puts 'Already stopped'
			end

			rescue Exception => e
				puts "Error deteniendo Todos #{e} #{nombres[i]}"
			end
			
		end
		

	
	else
		raise ArgumentError, 'unknown option: ' + ARGV[0]
end