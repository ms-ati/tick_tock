module TickTock
  module Wraps
    def wrap_block(**tick_kw_args)
      card = tick(**tick_kw_args)
      yield card
    ensure
      tock(card)
    end

    def wrap_proc(**tick_kw_args, &proc_to_wrap)
      proc do |*proc_args|
        tick_kw_args_1, proc_args_1 =
          process_tick_parent_card(tick_kw_args, proc_args)

        tick_kw_args_2 =
          process_tick_subject(tick_kw_args_1, proc_args_1)

        wrap_block(**tick_kw_args_2) do
          proc_to_wrap.call(*proc_args_1)
        end
      end
    end

    def wrap_lazy(lazy_enum_to_wrap, wrap_card: false, **tick_kw_args)
      lazy_tick, lazy_tock, lazy_card = create_lazy_callbacks(**tick_kw_args)

      enum_to_wrap =
        if wrap_card
          lazy_enum_to_wrap.lazy.map do |*elements|
            WrappedElementsWithLazyCard.new(
              lazy_card: lazy_card,
              elements: elements
            )
          end
        else
          lazy_enum_to_wrap
        end

      [
        [:dummy].lazy.flat_map(&lazy_tick),

        enum_to_wrap,

        [:dummy].lazy.flat_map(&lazy_tock)
      ].
        lazy.
        flat_map(&:itself)
    end

    private

    class WrappedElementsWithLazyCard
      attr_reader :lazy_card, :elements

      def initialize(lazy_card:, elements:)
        @lazy_card = lazy_card
        @elements = elements
      end
    end
    private_constant :WrappedElementsWithLazyCard

    def process_tick_parent_card(tick_kw_args, proc_args)
      arg = proc_args.first

      case arg
      when WrappedElementsWithLazyCard
        [
          tick_kw_args.merge(parent_card: arg.lazy_card.call),
          arg.elements
        ]
      else
        [tick_kw_args, proc_args]
      end
    end

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
    # lazily, and can be wired up using {Enumerator::Lazy#flat_map}. Also
    # returns a third `Proc` which returns the card itself, or `nil` if it has
    # not been created yet.
    #
    # @return [Array(Proc, Proc, Proc)]
    #   Two Procs which perform the "lazy tick" and "lazy tock" callbacks, and a
    #   third which returns the "lazy card" created in the shared state.
    def create_lazy_callbacks(**tick_kw_args)
      shared_state = [nil]

      lazy_card = proc { shared_state[0] }

      lazy_tick = proc do
        shared_state[0] = tick(**tick_kw_args)
        [] # return no elements into a lazy `#flat_map`
      end

      lazy_tock = proc do
        shared_state[0] = tock(lazy_card.call)
        [] # return no elements into a lazy `#flat_map`
      end

      [lazy_tick, lazy_tock, lazy_card]
    end
  end
end
