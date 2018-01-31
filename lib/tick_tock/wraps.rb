require "tick_tock/local_context"

module TickTock
  CURRENT_CARD_KEY = :"__tick_tock/current_card__"

  module Wraps
    def wrap_block(**tick_kw_args)
      card = tick(**tick_kw_args)
      yield
    ensure
      tock(card: card)
    end

    def wrap_proc(callable_to_wrap = nil, **tick_kw_args, &proc_to_wrap)
      LocalContext.wrap_proc do |*proc_args|
        new_tick_kw_args = process_tick_subject(tick_kw_args, proc_args)

        wrap_block(**new_tick_kw_args) do
          (callable_to_wrap || proc_to_wrap).call(*proc_args)
        end
      end
    end

    def wrap_lazy(lazy_enum_to_wrap, **tick_kw_args)
      lazy_tick, lazy_tock = create_lazy_callbacks(**tick_kw_args)

      arr_with_callbacks = [
        [:dummy].lazy.flat_map(&lazy_tick),
        lazy_enum_to_wrap.lazy,
        [:dummy].lazy.flat_map(&lazy_tock)
      ]

      arr_with_callbacks.lazy.flat_map(&:itself)
    end

    private

    # If the `subject` is itself a proc, process the wrapped proc's *args*
    # to actually generate the subject for the wrapped timing.
    #
    # @param tick_kw_args [Hash]
    # @param proc_args [Array]
    # @return [Array] args to actually be passed to {#tick}
    def process_tick_subject(tick_kw_args, proc_args)
      subject = tick_kw_args[:subject]

      if subject&.respond_to?(:call)
        tick_kw_args.merge(subject: subject.call(*proc_args))
      else
        tick_kw_args
      end
    end

    # Creates shared state for a lazily-created punch card, and returns two
    # `Proc` objects which use that state to do the `tick` and `tock` methods
    # lazily, and can be wired up using {Enumerator::Lazy#flat_map}.
    #
    # @return [Array(Proc, Proc, Proc)]
    #   Two Procs which perform the "lazy tick" and "lazy tock" callbacks
    def create_lazy_callbacks(**tick_kw_args)
      shared_state = [nil]

      lazy_tick = proc do
        shared_state[0] = tick(**tick_kw_args)
        [] # return no elements into a lazy `#flat_map`
      end

      lazy_tock = proc do
        shared_state[0] = tock(card: shared_state[0])
        [] # return no elements into a lazy `#flat_map`
      end

      [lazy_tick, lazy_tock]
    end
  end
end
