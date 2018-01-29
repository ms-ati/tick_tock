require "tick_tock/local_context"
require "tick_tock/punch"
require "tick_tock/timer"
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
  end
end
