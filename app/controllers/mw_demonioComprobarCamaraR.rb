require 'rubygems'        # if you use RubyGems
require 'daemons'

options = {
  :app_name   => "demonioComprobarCamara",
  :ARGV       => ['start', '-f']
  :dir        => 'pids',
  :multiple   => true,
  :ontop      => true,
  :mode       => :exec,
  :backtrace  => true,
  :monitor    => true
}

Daemons.run(File.join(File.dirname(__FILE__), 'demonioComprobarCamaraR.rb'),options)
