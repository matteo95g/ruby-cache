class Parser

  MAX_FLAG = 65536

  attr_accessor :comando
  attr_accessor :clave
  attr_accessor :flags
  attr_accessor :TTL
  attr_accessor :size
  attr_accessor :cas_token
  attr_accessor :no_reply

  def valid?(comando)
    array = comando.split(' ')
    if ((array[0] == "set" || array[0] == "add" || array[0] == "replace" || array[0] == "append" || array[0] == "prepend") && array[1] != nil && array[2] != nil && array[3] != nil && array[4] != nil && array[6] == nil)
      true
    elsif ((array[0] == "get" || array[0] == "gets") && array[1] != nil)
      true
    elsif 
      array[0] == "cas" && array[1] != nil && array[2] != nil && array[3] != nil && array[4] != nil && array[5] != nil
      true
    else
      false
    end         
  end

  def are_num?(flags,ttl,size)
    ttl.match(/^\d+$/) && flags.match(/^\d+$/) && size.match(/^\d+$/) ? true : false
  end

  def flag_ok?(flags)
    Integer(flags) < MAX_FLAG ? true : false
  end

  def validate(flags, ttl, size)
    are_num?(flags, ttl, size) && flag_ok?(flags)
  end

  def descomponer(entrada)
    array = entrada.split
    @clave = Array.new
    @comando = array[0]
    if @comando == "get" || @comando == "gets"
      i = 1
      while array[i] != nil
        @clave.push(array[i])
        i += 1              
      end
    elsif @comando == "set" || @comando == "add" || @comando == "replace" || @comando == "append" || @comando == "prepend" 
      @clave.push(array[1])
      @flags = array[2]
      @TTL = array[3]
      @size = array[4]
      if array[5] == "noreply"
        @no_reply = true
      else
        @no_reply = false
      end
    elsif @comando == "cas"
      @clave.push(array[1])
      @flags = array[2]
      @TTL = array[3]
      @size = array[4]
      @cas_token = array[5]   
      if array[6] == "noreply"
        @no_reply = true
      else
        @no_reply = false
      end     
    end
  end
end