require "tick_tock/punch"
require "tick_tock/version"

module TickTock
  module_function

  def tick(subject: nil, parent_card: nil)
    card = punch.card(subject: subject, parent_card: parent_card)
    punch.in(card)
  end

  def tock(card)
    punch.out(card)
  end

  def wrap_yield
    raise ArgumentError unless block_given?
    card = tick
    result = yield
    tock(card)
    result
  end

  def wrap_proc
    raise ArgumentError unless block_given?
    proc do |*args|
      wrap_yield do
        yield(*args)
      end
    end
  end

  def wrap_lazy(enum)
    card_state = [nil]
    do_tick = -> { card_state[0] = tick; [] }
    do_tock = -> { card_state[0] = tock(card_state[0]); [] }

    [
      [:dummy].lazy.flat_map(&do_tick),
      enum,
      [:dummy].lazy.flat_map(&do_tock)
    ].
      lazy.
      flat_map(&:itself)
  end

  def punch
    @punch ||= Punch.default
  end
end
