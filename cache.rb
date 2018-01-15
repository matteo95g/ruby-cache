require 'singleton'

class Cache
	include Singleton
	attr_accessor :memcached

	def initialize
    @memcached = Hash.new
    @mutex_set = Hash.new
    timer
  end

  def set(key, value)
    @mutex_set[key] = Mutex.new
    @mutex_set[key].synchronize do
  	  @memcached[key] = value
    end
  end

  def get(key)
    return @memcached[key]
  end

  def delete(key)
    @memcached.delete(key)
  end

  private

  def timer
    timer = Thread.new{
      while true
        sleep 1
        if memcached
          memcached.each do |key, value|
            if !value.no_delete
              if value.ttl <= 0 
                delete(key)
                @mutex_set.delete(key)
              else
                value.ttl -= 1
              end
            end
          end
        end
      end
    }
  end

end

