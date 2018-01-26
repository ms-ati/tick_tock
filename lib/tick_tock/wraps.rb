module TickTock
  module Wraps
    def wrap_block(*tick_args)
      card = tick(*tick_args)
      yield card
    ensure
      tock(card)
    end

    def wrap_proc(*tick_args, &proc_to_wrap)
      proc do |*proc_args|
        new_tick_args = call_subject_if_necessary(tick_args, proc_args)

        wrap_block(*new_tick_args) do
          proc_to_wrap.call(*proc_args)
        end
      end
    end

    def wrap_lazy(lazy_enum_to_wrap, *tick_args)
      lazy_tick, lazy_tock = create_lazy_callbacks(*tick_args)

      [
        [:dummy].lazy.flat_map(&lazy_tick),
        lazy_enum_to_wrap,
        [:dummy].lazy.flat_map(&lazy_tock)
      ].
        lazy.
        flat_map(&:itself)
    end

    private

    # If the subject was itself a Proc, process the wrapped proc's *args*
    # to actually generate the subject for the wrapped timing.
    #
    # @param tick_args [Array]
    # @param proc_args [Array]
    # @return [Array] args to actually be passed to {#tick}
    def call_subject_if_necessary(tick_args, proc_args)
      kw_args = tick_args.last
      subject = kw_args&.is_a?(Hash) ? kw_args[:subject] : nil

      if subject&.respond_to?(:call)
        new_kw_args = kw_args.merge(subject: subject.call(*proc_args))
        tick_args.take(tick_args.length - 1) << new_kw_args
      else
        tick_args
      end
    end

    # Creates a bit of shared state for a lazy punch card, and returns two
    # `Proc` objects which use that state to do the `tick` and `tock` methods
    # lazily, and can be wired up using {Enumerator::Lazy#flat_map}.
    #
    # @return [Array(Proc, Proc)]
    #   Two Procs which perform the "lazy tick" and "lazy tock"
    def create_lazy_callbacks(*tick_args)
      shared_card_state = [nil]

      lazy_tick = proc do
        shared_card_state[0] = tick(*tick_args)
        [] # return no elements into a lazy `#flat_map`
      end

      lazy_tock = proc do
        shared_card_state[0] = tock(shared_card_state[0])
        [] # return no elements into a lazy `#flat_map`
      end

      [lazy_tick, lazy_tock]
    end
  end
end
