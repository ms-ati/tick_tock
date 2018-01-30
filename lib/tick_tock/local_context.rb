module TickTock
  # LocalContext provides the conveniences of Thread-local (or Fiber-local)
  # variables to asynchronous code, where a given Proc may end up executing on a
  # different thread or fiber from the one in which its local context existed.
  #
  # Also useful for Procs created on the same thread, but executed at a later
  # time or lazily.
  #
  # See {#wrap_proc} for an example of how this can be used.
  #
  # Here's how the same concept is implemented in the Monix library in Scala:
  # https://github.com/monix/monix/blob/v3.0.0-M3/monix-execution/shared/src/main/scala/monix/execution/misc/Local.scala
  module LocalContext
    module_function

    # @return [Hash] Default context is an empty hash
    DEFAULT_CONTEXT = {}.freeze

    # @return [Symbol] Key under which context is store as a fiber-local var
    FIBER_LOCAL_KEY = :"__tick_tock/local_context__"

    # Wraps the current local context into the given proc, so that when it is
    # run it has access to the same local context as when it was wrapped, even
    # if it is run in a different Thread, Fiber, or simply at a later time after
    # the local context was changed.
    #
    # @example Wrap current local context into a Proc object
    #   a_proc = proc { TickTock::LocalContext[:foo] }
    #
    #   TickTock::LocalContext[:foo] = :bar
    #   wrapped_proc = TickTock::LocalContext.wrap_proc(&a_proc)
    #
    #   TickTock::LocalContext[:foo] = 42
    #   wrapped_proc.call
    #   #=> :bar
    #
    #   TickTock::LocalContext[:foo]
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

    # Updates the current local context to map `key` to `value`. Works in a
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

    # @return [Hash{String, Symbol => Object}]
    #   The current local context represented as a frozen hash.
    def context
      if Thread.current.key?(FIBER_LOCAL_KEY)
        Thread.current[FIBER_LOCAL_KEY]
      else
        DEFAULT_CONTEXT
      end
    end

    # Clears the current local context
    def clear!
      self.context = DEFAULT_CONTEXT
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
