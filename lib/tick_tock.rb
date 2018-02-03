require "tick_tock/clock"
require "tick_tock/version"

module TickTock
  module_function

  attr_accessor :clock
  module_function :clock, :clock=

  def tick(subject: nil)
    clock.tick(subject: subject)
  end

  def tock(card:)
    clock.tock(card: card)
  end

  def tick_tock(**tick_kw_args)
    card = tick(**tick_kw_args)
    yield
  ensure
    tock(card: card)
  end

  def wrap_proc(callable_to_wrap = nil, **tick_kw_args, &proc_to_wrap)
    proc do |*proc_args|
      # if subject was given as a Proc, apply it to the given args
      subject = tick_kw_args[:subject]
      subject = subject&.respond_to?(:call) ? subject.call(*proc_args) : subject
      new_tick_kw_args = tick_kw_args.merge(subject: subject)

      tick_tock(**new_tick_kw_args) do
        (callable_to_wrap || proc_to_wrap).call(*proc_args)
      end
    end
  end

  def wrap_proc_context(callable_to_wrap = nil, **tick_kw_args, &proc_to_wrap)
    wrapped_proc = wrap_proc(callable_to_wrap, **tick_kw_args, &proc_to_wrap)
    Locals.wrap_proc(&wrapped_proc)
  end

  def wrap_lazy(lazy_enum_to_wrap, **tick_kw_args)
    shared_state = [nil]

    lazy_tick = proc { shared_state[0] = tick(**tick_kw_args); [] }
    lazy_tock = proc { shared_state[0] = tock(card: shared_state[0]); [] }

    arr_with_callbacks = [
      [:dummy].lazy.flat_map(&lazy_tick),
      lazy_enum_to_wrap.lazy,
      [:dummy].lazy.flat_map(&lazy_tock)
    ]

    arr_with_callbacks.lazy.flat_map(&:itself)
  end
end

# Assigns a global default clock configuration
TickTock.clock = TickTock::Clock.default
