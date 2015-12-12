#!/usr/bin/env ruby -w
require "socket"

class Server
  def initialize ip, port
    @server = TCPServer.open ip, port
    @connections = Hash.new
    @rooms = Hash.new
    @clients = Hash.new
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
    run
  end
  
  def run
    loop {
      Thread.start @server.accept do |client|
        nick = client.gets.chomp.to_sym
        client.puts "hello #{nick}"
        @connections[:clients].each do |other_name, other_client|
          if nick == other_name || client == other_client
            client.puts "username already exists"
            Thread.kill self
          end
        end
        puts "#{nick} connected"
        @connections[:clients][nick] = client
        client.puts "connection established"
        listen_user_messages nick, client
      end
    }.join
  end

  def listen_user_messages username, client
    loop {
      msg = client.gets.chomp
      put_msg username, msg
    }
  end
  
  def put_msg user, msg
    message = "<#{Time.now.strftime "%H:%M:%S"}> #{user.to_s}: #{msg}"
    puts message
    @connections[:clients].each do |other_name, other_client|
      unless other_name == user
        puts "sending msg to #{other_name} #{other_client}"
        other_client.puts message
      end
    end
  end
 
end

server = Server.new "localhost", 3000
server.run
