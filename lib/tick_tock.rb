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

  def wrap_block(subject: nil)
    raise ArgumentError unless block_given?
    card = tick
    result = yield
    tock(card)
    result
  end

  def wrap_proc(subject: nil, &p)
    proc do |*args|
      wrap_block(subject: subject) do
        p.call(*args)
      end
    end
  end

  def wrap_lazy(enum, subject: nil)
    card_state = [nil]
    lazy_tick = ->(_) { card_state[0] = tick(subject: subject); [] }
    lazy_tock = ->(_) { card_state[0] = tock(card_state[0]); [] }

    [
      [:dummy].lazy.flat_map(&lazy_tick),
      enum,
      [:dummy].lazy.flat_map(&lazy_tock)
    ].
      lazy.
      flat_map(&:itself)
  end

  def punch
    @punch ||= Punch.default
  end
end
