require "tick_tock/clock"
require "tick_tock/version"

# {TickTock} makes it easy to wrap your Ruby code to measure nested timings and
# to log them -- even when the code is asynchronous or lazy, so straight-forward
# blocks do not work.
#
# The TickTock module uses Ruby's
# {http://ruby-doc.org/core-2.3.4/Module.html#method-i-module_function
# module_function} directive to enable two different usage patterns:
# 1. Calling methods directly on the module
# 2. Including the module into classes as a mix-in
#
# == Configuration
#
# When calling methods directly on the module, the instance of {TickTock::Clock}
# configured via {TickTock.clock=} will be used for all calls.
#
# On the other hand, when including the TickTock module into a class, the class
# may choose to override {#clock} to return a specific instance.
#
# @example 1. Calling TickTock methods directly on the module
#   TickTock.tick_tock(subject: "a block") do
#     times_2 = ->(n) { n * 2 }
#     [1, 2].map(&TickTock.tick_tock_proc(times_2, subject: :to_s.to_proc))
#   end
#   # => [2, 4]
#
#   # Logs the following
#   # I, [2018-02-04T14:22:01.1261 #26]  INFO -- : > Started a block
#   # I, [2018-02-04T14:22:01.1264 #26]  INFO -- : >> Started 1
#   # I, [2018-02-04T14:22:01.1265 #26]  INFO -- : << Completed 1 [0.000s]
#   # I, [2018-02-04T14:22:01.1267 #26]  INFO -- : >> Started 2
#   # I, [2018-02-04T14:22:01.1267 #26]  INFO -- : << Completed 2 [0.000s]
#   # I, [2018-02-04T14:22:01.1268 #26]  INFO -- : < Completed a block [0.001s]
#
# @example 2. Including the module into classes as a mix-in
#   class Times2
#     include TickTock
#
#     def call
#       tick_tock(subject: "a block") do
#         [1, 2].map(&tick_tock_proc(method(:times_2), subject: :to_s.to_proc))
#       end
#     end
#
#     def times_2(n)
#       n * 2
#     end
#   end
#
#   Times2.new.call
#   # => [2, 4]
#
#   # Logs the same as above
#
module TickTock
  class << self
    # @return [Clock]
    #   the configured global instance of Clock, assigned by calling {.clock=}.
    attr_accessor :clock
  end

  # @return [Clock]
  #   when the TickTock module is included in a class, by default returns the
  #   configured global instance of Clock. Override {#clock} in classes to
  #   return a class-specific instance instead.
  def clock
    self.class.clock
  end

  module_function

  # @!group Basics: Start and stop a timing context

  # Starts a new timing context, returns a "card" representing it.
  #
  # @param subject [Object]  Description of the subject we are timing
  # @return        [Object]  A new card representing the new timing context
  def tick(subject: nil)
    clock.tick(subject: subject)
  end

  # Completes a timing context represented by the given "card".
  #
  # @param card [Object]  A card representing the timing context to complete
  # @return     [Object]  The card after being marked completed
  def tock(card:)
    clock.tock(card: card)
  end

  # @!endgroup

  # @!group Helpers: Wrap an asynchronous construct in a timing context

  # Executes the given block in a timing context using {.tick} and {.tock}.
  #
  # @param subject [Object]  Description of the subject we are timing
  # @return        [Object]  Return value of the given block
  def tick_tock(subject: nil)
    card = tick(subject: subject)
    yield
  ensure
    tock(card: card)
  end

  # Wraps a
  # {http://ruby-doc.org/core-2.3.4/Enumerator/Lazy.html lazy enumerator} with
  # a timing context using *lazy* calls to {.tick} and {.tock}, which will be
  # called when the enumerator starts and completes enumeration respectively.
  #
  # @param lazy_enum_to_wrap [Enumerator::Lazy]  Lazy enumerator to wrap
  # @param subject           [Object]            Description of the subject
  # @return                  [Enumerator::Lazy]  Wrapped lazy enumerator
  def tick_tock_lazy(lazy_enum_to_wrap, subject: nil)
    shared_state = [nil]

    lazy_tick = proc { shared_state[0] = tick(subject: subject); [] }
    lazy_tock = proc { shared_state[0] = tock(card: shared_state[0]); [] }

    arr_with_callbacks = [
      [:dummy].lazy.flat_map(&lazy_tick),
      lazy_enum_to_wrap.lazy,
      [:dummy].lazy.flat_map(&lazy_tock)
    ]

    arr_with_callbacks.lazy.flat_map(&:itself)
  end

  # Wraps a Proc with a timing context using a call to {.tick_tock}. Can
  # optionally wrap the current nested timing contexts into the Proc, so that
  # when executed asynchronously it will retain the same context.
  #
  # @param callable_to_wrap [Proc, #call]
  #   Callable to wrap, given as a normal parameter.
  #
  # @param subject [Object, Proc, #call]
  #   Description of the subject, or optionally a function which, when called on
  #   the args that are actually eventually passed to the final proc, will
  #   generate the actual subject.
  #
  # @param proc_to_wrap [Proc]
  #   Alternatively you can pass the callable as a "block" parameter -- only
  #   used if callable_to_wrap is nil.
  #
  # @return [Proc]
  #   A Proc wrapping the given callable in a timing context.
  def tick_tock_proc(callable_to_wrap = nil, subject: nil, &proc_to_wrap)
    should_save_context = tick_kw_args.delete(:save_context)

    tt_proc = proc do |*proc_args|
      # if original subject was a Proc, apply it to args to create the subject
      subject = tick_kw_args[:subject]
      subject = subject&.respond_to?(:call) ? subject.call(*proc_args) : subject
      new_tick_kw_args = tick_kw_args.merge(subject: subject)

      tick_tock(**new_tick_kw_args) do
        (callable_to_wrap || proc_to_wrap).call(*proc_args)
      end
    end

    should_save_context ? Locals.wrap_proc(&tt_proc) : tt_proc
  end



  # @!endgroup
end

# Assigns a global default clock instance
TickTock.clock = TickTock::Clock.default
