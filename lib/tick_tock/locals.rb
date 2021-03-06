module TickTock
  # {Locals} provides the convenience of Thread-local (or Fiber-local) variables
  # to asynchronous code. By "asynchronous", we simply mean that a given Proc
  # may end up executing on a different Thread or Fiber from the one in which
  # it was created -- or equally -- on the same thread, but at a later time!
  #
  # See {.wrap_proc} for an example of how this can be used to capture local
  # state and wrap it with a Proc for later use, independent of how that state
  # may change during the intervening period.
  #
  # {https://github.com/monix/monix/blob/v3.0.0-M3/monix-execution/shared/src/main/scala/monix/execution/misc/Local.scala
  # Here's how similar concepts are implemented} in the Monix library in Scala.
  #
  module Locals
    module_function

    # @return [Hash] Default context is an empty hash
    DEFAULT_CONTEXT = {}.freeze
    private_constant :DEFAULT_CONTEXT

    # @return [Symbol] Key under which context is stored as a fiber-local var
    FIBER_LOCAL_KEY = :"__tick_tock/local_context__"
    private_constant :FIBER_LOCAL_KEY

    # Wraps the current local context into the given proc, so that when it is
    # run it has access to the same local context as when it was wrapped, even
    # if it is run in a different Thread, Fiber, or simply at a later time after
    # the local context was changed.
    #
    # @example Wrap current local context into a Proc object
    #   # proc which depends on some local variable
    #   a_proc = proc { "proc sees: " + TickTock::Locals[:foo].to_s }
    #
    #   # wraps the current state of the locals into the proc
    #   TickTock::Locals[:foo] = :bar
    #   wrapped_proc = TickTock::Locals.wrap_proc(&a_proc)
    #
    #   # later, the state of the locals change, but the wrapped state does not
    #   TickTock::Locals[:foo] = 42
    #   wrapped_proc.call
    #   #=> "proc sees: bar"
    #
    #   TickTock::Locals[:foo]
    #   #=> 42
    #
    # @param proc_to_wrap [Proc]  A proc to wrap with the current local context
    # @return [Proc]              Wrapped version of the given `proc_to_wrap`
    def wrap_proc(&proc_to_wrap)
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

    # Fetches current value of given `key` in the local context.
    #
    # @param key [String, Symbol]  Key to fetch
    # @return [Object]             Current value of `key` in local context
    # @raise [KeyError]            Raise if key not found
    def [](key)
      context.fetch(key)
    end

    # Updates the current local context to map *key* to *value*. Works in a
    # non-mutative way, so that any other references to the old context will be
    # left unchanged.
    #
    # @param key [String, Symbol]  Key to set a value for
    # @param value [Object]        Value to set for `key` in local context
    # @return [Object]             The value that was set
    def []=(key, value)
      self.context = context.merge(key => value).freeze
    end

    # Check if the given key is currently set in the local context.
    #
    # @param key [String, Symbol]  Key to check for
    # @return [Boolean]            Is the key currently set?
    def key?(key)
      context.key?(key)
    end

    # Clears the current local context
    def clear!
      self.context = DEFAULT_CONTEXT
    end

    # @return [Hash{String, Symbol => Object}]
    #   The current local context represented as a frozen hash.
    def context
      if Thread.current.key?(FIBER_LOCAL_KEY)
        Thread.current[FIBER_LOCAL_KEY]
      else
        DEFAULT_CONTEXT
      end
    end

    # @api private
    #
    # Sets the local context to the given frozen hash.
    #
    # @param hsh [Hash]  Frozen hash to set as current local context
    def context=(hsh)
      Thread.current[FIBER_LOCAL_KEY] = hsh
    end
    private_class_method :context=
  end
end
