require 'rubygems'        # if you use RubyGems
require 'daemons'

options = {
  :app_name   => "demonioBuscarFotos",
  :ARGV       => ['start', '-f']
  :dir        => 'pids',
  :multiple   => true,
  :ontop      => true,
  :mode       => :exec,
  :backtrace  => true,
  :monitor    => true
}

Daemons.run(File.join(File.dirname(__FILE__), 'demonioBuscarFotosR.rb'),options)
