module TickTock
  class LocalContext
    EMPTY = {}.freeze
    FIBER_LOCAL_KEY = :"__tick_tock/local_context__"

    def self.[](key)
      context.fetch(key)
    end

    def self.[]=(key, value)
      self.context = context.merge(key => value).freeze
    end

    def self.context
      unless Thread.current.key?(FIBER_LOCAL_KEY)
        Thread.current[FIBER_LOCAL_KEY] = EMPTY
      end
      Thread.current[FIBER_LOCAL_KEY]
    end

    def self.context=(hsh)
      Thread.current[FIBER_LOCAL_KEY] = hsh
    end

    def self.wrap_proc(proc_to_wrap)
      wrapped_context = context

      proc do |*args|
        begin
          saved_context = context
          self.context = wrapped_context
          proc_to_wrap.call(*args)
        ensure
          self.context = saved_context
        end
      end
    end
  end
end
