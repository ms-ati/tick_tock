require "tick_tock/clock"
require "tick_tock/locals"
require "tick_tock/punch"
require "tick_tock/version"

module TickTock
  TIMER_METHODS = [:tick, :tock, :wrap_block, :wrap_proc, :wrap_lazy].freeze

  class << self
    extend Forwardable

    delegate TIMER_METHODS => :default_timer

    def default_timer
      @default_timer ||= Timer.new(Punch.default)
    end

    def default_timer=(timer)
      @default_timer = timer
    end

    def current_card_in_local_context
      if TickTock::LocalContext.key?(CURRENT_CARD_KEY)
        TickTock::LocalContext[CURRENT_CARD_KEY]
      else
        nil
      end
    end
  end
end
