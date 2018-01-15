#load 'parser.rb'
#load 'cache.rb'
#load 'node.rb'

require_relative "parser"
require_relative "cache"
require_relative "node"

#mensajes de salida
ERROR = "ERROR"
BAD_LINE = "CLIENT_ERROR bad command line format"
NOT_STORED = "NOT_STORED"
STORED = "STORED"
NOT_FOUND = "NOT_FOUND"
BAD_CHUNK = "CLIENT_ERROR bad data chunk"
C_END = "END"
EXISTS = "EXISTS"

#comandos
QUIT = "quit"
SET = "set"
GET = "get"
GETS = "gets"
ADD = "add"
REPLACE = "replace"
APPEND = "append"
PREPEND = "prepend"
CAS = "cas"

class Controller

  def do_command(conn)
    command = conn.gets
    command = command.chomp
    if command == QUIT
      conn.close
    else
      parser = Parser.new
      if parser.valid?(command)
        parser.descomponer(command)
        case parser.comando
        when SET
          do_set(parser, conn)
        when GET, GETS
          do_get_or_gets(parser, conn)
        when ADD
          do_add(parser, conn)
        when REPLACE
          do_replace(parser, conn)
        when APPEND, PREPEND
          do_append_or_prepend(parser, conn)
        when CAS
          do_cas(parser, conn)
        end
      else    
        conn.puts(ERROR)
      end
    end
  end

  private
  
  def read_data(conn, size, parser)
    data = conn.gets
    data = data.chomp
    while data.length < size do
      data += "\n"
      new_data = conn.gets
      new_data = new_data.chomp
      data += new_data
      data += "\n"
    end
    if data.length == size
      return true, data
    else
      res = parser.no_reply ? ERROR :  BAD_CHUNK + "\n" + ERROR
      return false, res
    end
  end

  def do_add(parser, conn)
    if parser.validate(parser.flags, parser.TTL, parser.size)
      if get(parser.clave[0]) == nil
        do_set(parser, conn)
      else
        ok, res = read_data(conn, Integer(parser.size), parser)
        if !ok 
          conn.puts(res)
        elsif !parser.no_reply
          conn.puts(NOT_STORED)
        end
      end
    else
      conn.puts(BAD_LINE) if !parser.no_reply
    end
  end

  def do_replace(parser, conn)
    if parser.validate(parser.flags, parser.TTL, parser.size)
      if get(parser.clave[0])
        do_set(parser, conn)
      else
        ok, data = read_data(conn, Integer(parser.size), parser)
        if ok 
          conn.puts(NOT_STORED) if !parser.no_reply
        else
          conn.puts(data) 
        end
      end
    else
      if !parser.no_reply
        conn.puts(BAD_LINE) 
      else
        conn.gets
        conn.puts(ERROR)
      end
    end
  end

  def set(key, data, ttl, flags)
    cache = Cache.instance
    ttl = Integer(ttl)
    flags = Integer(flags)
    value = ttl == 0 ? Node.new(data, ttl, flags, true) : Node.new(data, ttl, flags, false)  
    cache.set(key, value)    
  end

  def do_set(parser, conn)
    if parser.validate(parser.flags, parser.TTL, parser.size)
      ok, data = read_data(conn, Integer(parser.size), parser)
      if ok
        set(parser.clave[0], data, parser.TTL, parser.flags)
        conn.puts(STORED) if !parser.no_reply
      else
        conn.puts(data)
      end
    else
      if !parser.no_reply
        conn.puts(BAD_LINE)
      else
        conn.gets
        conn.puts(ERROR)
      end
    end
  end

  def do_cas(parser, conn)
    if parser.validate(parser.flags, parser.TTL, parser.size) && parser.cas_token.match(/^\d+$/)
      if get(parser.clave[0])
        strc = get(parser.clave[0])
        if Integer(strc.cas_token) == Integer(parser.cas_token) 
          do_set(parser, conn)
        else
          conn.gets
          conn.puts(EXISTS) if !parser.no_reply
        end
      else
        conn.gets
        conn.puts(NOT_FOUND) if !parser.no_reply
      end
    else
      parser.no_reply ? conn.puts(ERROR) : conn.puts(BAD_LINE)
    end
  end

  def do_get_or_gets(parser, conn)
    if parser.comando == GET
      conn.puts(do_get(parser.clave, false))
    elsif parser.comando == GETS
      conn.puts(do_get(parser.clave, true))
    end
  end

  def get(clave)
    cache = Cache.instance
    return cache.get(clave)
  end

  def do_get(clave, is_gets)
    res = ""
    for i in 0..clave.length - 1
        if get(clave[i])
          strc = get(clave[i])
          if is_gets
            res += "VALUE " + clave[i] + " " + strc.flags.to_s + " " + strc.data.length.to_s + " "  + strc.cas_token.to_s + "\r\n"
          else
            res += "VALUE " + clave[i] + " " + strc.flags.to_s + " " + strc.data.length.to_s + "\r\n"
          end          
          res += strc.data.strip + "\r\n"
        end
      end
    res += C_END
  end

  def do_append_or_prepend(parser, conn)
    if parser.validate(parser.flags, parser.TTL, parser.size)
      ok, data = read_data(conn, Integer(parser.size), parser)
      if ok
        strc = get(parser.clave[0])
        if strc
          if parser.comando == APPEND        
            set(parser.clave[0], strc.data + data, parser.TTL, parser.flags)
          else
            set(parser.clave[0], data + strc.data, parser.TTL, parser.flags)
          end
          conn.puts(STORED) if !parser.no_reply
        else
          conn.puts(NOT_STORED) if !parser.no_reply
        end
      else
        conn.puts(data)
      end
    else
      conn.puts(BAD_LINE) if !parser.no_reply
    end
  end

  

end