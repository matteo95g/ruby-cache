class Node

  @@cas_token = 0

  attr_accessor :data
  attr_accessor :ttl
  attr_accessor :flags
  attr_accessor :no_delete

  def initialize(data, ttl, flags, no_delete)
    @data = data
    @ttl = ttl
    @flags = flags
    @no_delete = no_delete
    @@cas_token += 1
  end

  def cas_token
    @@cas_token
  end

end