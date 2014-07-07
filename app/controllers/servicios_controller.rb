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
require 'win32/service'
require 'rbconfig'
include Win32
include Config

# Make sure you're using the version you think you're using.
puts 'VERSION: ' + Service::VERSION

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
	when 'installmwservice'
		Service.delete('-mw')
		
	when 'installserverservice'
		Service.new(
				:service_name     => nombres[nombresDemonios[ARGV[1]]],
				:display_name     => nombres[nombresDemonios[ARGV[1]]],
				:description      => descripcion[nombresDemonios[ARGV[1]]],
				:dependencies       => ['W32Time','Schedule'],
				:start_type         => Service::AUTO_START,:load_order_group   => 'Network',
				:error_control      => Service::ERROR_NORMAL,
				:service_type       => Service::WIN32_OWN_PROCESS,
				:binary_path_name => cmd
			)
	when 'installall'
		
			
		
		for i in 0..3
			begin
			ruta = demonios[i]
			cmd = ruby + pathOriginal + '\\'+"#{ruta}"+'"'
			Service.new(
				:service_name     => nombres[i],
				:display_name     => nombres[i],
				:description      =>descripcion[i],
				:dependencies       => ['W32Time','Schedule'],
				:start_type         => Service::AUTO_START,:load_order_group   => 'Network',
				:error_control      => Service::ERROR_NORMAL,
				:service_type       => Service::WIN32_OWN_PROCESS,
				:binary_path_name => cmd
			)
			rescue Exception => e
				puts "Error instalando todos #{e} #{nombres[i]}"
			end
			puts 'Service ' +  nombres[i]+ ' installed'   
			
		end
		# Service.new(
		# 		:service_name     => 'Servidores-Tesis',
		# 		:display_name     => 'Servidores-Tesis',
		# 		:description      =>'Script que inicia los servidores de la tesis',
		# 		:dependencies       => ['W32Time','Schedule'],
		# 		:start_type         => Service::AUTO_START,:load_order_group   => 'Network',
		# 		:error_control      => Service::ERROR_NORMAL,
		# 		:service_type       => Service::WIN32_OWN_PROCESS,
		# 		:binary_path_name => 'C:\Users\Luis\Dropbox\Tesis\Dropbox\Milagros\Tesis\mw\hm.vbs'
		# 	)
		# puts 'Service Servidores-Tesis installed'  
	when "install"
		begin
			ruta = demonios[nombresDemonios[ARGV[1]]]
			cmd = ruby + pathOriginal + '\\'+"#{ruta}"+'"'
			Service.new(
				:service_name     => nombres[nombresDemonios[ARGV[1]]],
				:display_name     => nombres[nombresDemonios[ARGV[1]]],
				:description      => descripcion[nombresDemonios[ARGV[1]]],
				:dependencies       => ['W32Time','Schedule'],
				:start_type         => Service::AUTO_START,:load_order_group   => 'Network',
				:error_control      => Service::ERROR_NORMAL,
				:service_type       => Service::WIN32_OWN_PROCESS,
				:binary_path_name => cmd
			)
			puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' installed'     
		rescue Exception => e
			puts "Error instalando #{e}"
		end 
	when 'start' 
		begin
			if Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'running'
				Service.start(nombres[nombresDemonios[ARGV[1]]], nil, 'hello', 'world')
				while Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'running'
					puts 'One moment...' + Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state
					sleep 1
				end
				puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' started'
			else
				puts 'Already running'
			end
		rescue Exception => e
			puts "Error iniciando #{e}"
		end
	when 'startall' 
			for i in 0..3
				begin
					puts 'Service ' + nombres[i] + ' iniciando'
					if Service.status(nombres[i]).current_state != 'running'

						Service.start(nombres[i], nil, 'hello', 'world')
						while Service.status(nombres[i]).current_state != 'running'
							puts 'One moment...' + Service.status(nombres[i]).current_state
							sleep 1
						end
						puts 'Service ' + nombres[i] + ' started'
					else
						puts 'Already running'
					end

				rescue Exception => e
					puts "Error iniciando todos #{e} #{nombres[i]}"
				end
				
			end

				# begin
				# 	puts 'Service Servidores-Tesis iniciando'
				# 	if Service.status('Servidores-Tesis').current_state != 'running'

				# 		Service.start('Servidores-Tesis', nil, 'hello', 'world')
				# 		while Service.status('Servidores-Tesis').current_state != 'running'
				# 			puts 'One moment...' + Service.status('Servidores-Tesis').current_state
				# 			sleep 1
				# 		end
				# 		puts 'Service Servidores-Tesis started'
				# 	else
				# 		puts 'Already running'
				# 	end

				# rescue Exception => e
				# 	puts "Error iniciando todos #{e} Servidores-Tesis"
				# end
			
		

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

			begin 
			if Service.status('Servidores-Tesis').current_state != 'stopped'
				Service.stop('Servidores-Tesis')
				while Service.status('Servidores-Tesis').current_state != 'stopped'
					puts 'One moment...' + Service.status('Servidores-Tesis').current_state
					sleep 1
				end
				puts 'Service Servidores-Tesis stopped'
			else
				puts 'Already stopped'
			end

			rescue Exception => e
				puts "Error deteniendo Todos #{e} 'Servidores-Tesis'"
			end


	when 'uninstall', 'delete'
		begin 
			if Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'stopped'
				Service.stop(nombres[nombresDemonios[ARGV[1]]])
			end
			while Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'stopped'
				puts 'One moment...' + Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state
				sleep 1
			end
			Service.delete(nombres[nombresDemonios[ARGV[1]]])
			puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' deleted'
		rescue Exception => e
			puts "Error Borrando #{e}"
		end

	when 'uninstallall', 'deleteall'
		 
			for i in 0..3
				begin
				if Service.status(nombres[i]).current_state != 'stopped'
					Service.stop(nombres[i])
				end
				while Service.status(nombres[i]).current_state != 'stopped'
					puts 'One moment...' + Service.status(nombres[i]).current_state
					sleep 1
				end
				Service.delete(nombres[i])
				puts 'Service ' + nombres[i] + ' deleted'
				
				rescue Exception => e
					puts "Error Borrando Todos #{e} #{nombres[i]}"
				end
			end

			begin
				if Service.status('Servidores-Tesis').current_state != 'stopped'
					Service.stop('Servidores-Tesis')
				end
				while Service.status('Servidores-Tesis').current_state != 'stopped'
					puts 'One moment...' + Service.status('Servidores-Tesis').current_state
					sleep 1
				end
				Service.delete('Servidores-Tesis')
				puts 'Service Servidores-Tesis deleted'
				
				rescue Exception => e
					puts "Error Borrando Todos #{e} 'Servidores-Tesis'"
				end
		
	when 'pause'
		begin
			if Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'paused'
				Service.pause(nombres[nombresDemonios[ARGV[1]]])
				while Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'paused'
					puts 'One moment...' + Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state
					sleep 1
				end
					puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' paused'
				else
					puts 'Already paused'
			end
		rescue Exception => e
			puts "Error pausando #{e}"
		end
	when 'pauseall'
		begin
		for i in 0..3
			if Service.status(nombres[i]).current_state != 'paused'
				Service.pause(nombres[i])
				while Service.status(nombres[i]).current_state != 'paused'
					puts 'One moment...' + Service.status(nombres[i]).current_state
					sleep 1
				end
				puts 'Service ' + nombres[i] + ' paused'
			else
				puts 'Already paused'
			end
			
		end
		rescue Exception => e
			puts "Error pausando Todos #{e}"
		end

	when 'resume'
		begin
		if Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'running'
			Service.resume(nombres[nombresDemonios[ARGV[1]]])
			while Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state != 'running'
				puts 'One moment...' + Service.status(nombres[nombresDemonios[ARGV[1]]]).current_state
				sleep 1
			end
			puts 'Service ' + nombres[nombresDemonios[ARGV[1]]] + ' resumed'
		else
			puts 'Already running'
		end
		rescue Exception => e
			puts "Error resume #{e}"
		end
	when 'resumeall'
		begin
		for i in 0..3
			if Service.status(nombres[i]).current_state != 'running'
				Service.resume(nombres[i])
				while Service.status(nombres[i]).current_state != 'running'
					puts 'One moment...' + Service.status(nombres[i]).current_state
					sleep 1
				end
				puts 'Service ' + nombres[i] + ' resumed'
			else
				puts 'Already running'
			end
			
		end
		rescue Exception => e
			puts "Error resumeall #{e}"
		end

	else
		raise ArgumentError, 'unknown option: ' + ARGV[0]
end