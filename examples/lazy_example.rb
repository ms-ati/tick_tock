require "pp"
require "tick_tock"

lazy_enum = [1, 2, 3].lazy

slow_proc = ->(n) { sleep(1); n * 2 }

# See how these can be defined elsewhere, but end up logging hierarchically
wrapped_slow_proc =
  TickTock.tick_tock_proc(slow_proc, subject: ->(n) { "Num #{n}" })

wrapped_lazy_enum =
  TickTock.tick_tock_lazy(lazy_enum, subject: "Lazy Enum")

# Here we both log the block and also hierarchically log what happens inside it:
result =
  TickTock.tick_tock(subject: "Top Level") do
    wrapped_lazy_enum.map(&wrapped_slow_proc).to_a
  end

pp result
