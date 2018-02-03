require "tick_tock/clock"
require "tick_tock/version"

module TickTock
  class << self
    attr_accessor :clock
  end

  module_function

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

  def tick_tock_proc(callable_to_wrap = nil, **tick_kw_args, &proc_to_wrap)
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

  def tick_tock_lazy(lazy_enum_to_wrap, **tick_kw_args)
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
