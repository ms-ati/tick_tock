require "tick_tock/card"
require "tick_tock/card_logger"
require "tick_tock/locals"
require "tick_tock/punch"

module TickTock
  # A {TickTock::Clock} can {#tick} and then {#tock}. Inspired by the
  # {https://en.wikipedia.org/wiki/Time_clock "punch-card" or "bundy" clock}
  # (where workers carry their own cards to punch in and out): the instances of
  # Clock are immutable, and the states of timing contexts are kept on "cards".
  #
  # == Punch cards
  #
  # This class delegates to a {TickTock::Punch} implementation (via {#punch}) in
  # order to obtain cards, to punch them in, and to punch them out. It does not
  # depend on any details of those classes. It is therefore possible to replace
  # the implementation of {Punch} - for example, to provide an alternate time
  # source, or to use a memory-optimized representation of the punch cards.
  #
  # == Hierarchical state
  #
  # To represent the hierarchy of currently active punch cards, we use {Locals},
  # which allows us to get and set state in a manner analogous to thread-local
  # variables, but which can be captured and accessed across asynchronous
  # contexts.
  #
  # == Logging and any other side-effects
  #
  # Callbacks {#on_tick} and {#on_tock} define logging (and any other
  # {https://en.wikipedia.org/wiki/Side_effect_(computer_science) side-effects})
  # which should take place on *ticks* and *tocks*.
  #
  # @!parse
  #   class Clock
  #     # @!group Class Methods due to being a Value object
  #
  #     # Constructor accepting keyword args.
  #     #
  #     # @param punch   [Punch]      Implementation of {Punch} to use
  #     # @param on_tick [Proc, nil]  Callback on {#tick}
  #     # @param on_tock [Proc, nil]  Callback on {#tock}
  #     # @return [Clock]
  #     def self.with(punch:, on_tick:, on_tock:); end
  #
  #     # @!endgroup
  #
  #     # @!group Instance Methods due to being a Value object
  #
  #     # @param punch   [Punch]      Implementation of {Punch} to use
  #     # @param on_tick [Proc, nil]  Callback on {#tick}
  #     # @param on_tock [Proc, nil]  Callback on {#tock}
  #     def initialize(punch, on_tick, on_tock); end
  #
  #     # @return [Clock]
  #     #   a copy of this instance with any given values replaced.
  #     #
  #     # @param punch   [Punch]      Implementation of {Punch} to use
  #     # @param on_tick [Proc, nil]  Callback on {#tick}
  #     # @param on_tock [Proc, nil]  Callback on {#tock}
  #     def with(punch: nil, on_tick: nil, on_tock: nil); end
  #
  #     # @!endgroup
  #   end
  #
  # @attr_reader punch   [Punch]      Implementation of {Punch} to use
  # @attr_reader on_tick [Proc, nil]  Callback on {#tick}
  # @attr_reader on_tock [Proc, nil]  Callback on {#tock}
  class Clock < Value.new(:punch, :on_tick, :on_tock)
    # @return [Clock]  an instance with the default configuration
    def self.default
      log_card = CardLogger.default.method(:call)
      with(punch: Punch.default, on_tick: log_card, on_tock: log_card)
    end

    # Starts timing a new card, calls any given {#on_tick}, and returns it.
    #
    # @param subject [Object]  Description of the subject we are timing
    # @return        [Object]  A new card representing the new timing context
    def tick(subject: nil)
      card = punch.card(subject: subject, parent_card: self.class.current_card)
      card_in = punch.in(card)
      self.class.current_card = card_in
      on_tick&.call(card_in)
      card_in
    end

    # Completes timing the given card, calls any given {#on_tock}, and returns
    # it.
    #
    # @param card [Object]  A card representing the timing context to complete
    # @return     [Object]  The card after being marked completed
    def tock(card:)
      card_out = punch.out(card)
      self.class.current_card = punch.parent_card_of(card_out)
      on_tock&.call(card_out)
      card_out
    end

    def with_added_on_tick(proc_to_add)
      with(on_tick: self.class.compose_procs_arity_1(proc_to_add, on_tick))
    end

    def with_added_on_tock(proc_to_add)
      with(on_tock: self.class.compose_procs_arity_1(proc_to_add, on_tock))
    end

    private

    # @return [Symbol]  Key to store and retrieve current punch card in {Locals}
    CURRENT_CARD = :"__tick_tock/current_card__"
    private_constant :CURRENT_CARD

    # @return [Card]  The currently active punch card
    def self.current_card
      Locals.key?(CURRENT_CARD) ? TickTock::Locals[CURRENT_CARD] : nil
    end

    # Sets the currently active punch card
    def self.current_card=(card)
      Locals[CURRENT_CARD] = card
    end

    def self.compose_procs_arity_1(proc_to_add, current)
      ->(x) { proc_to_add.call(current.call(x)) }
    end
  end
end
