require "pp"
require "tick_tock"

lazy_enum = [1, 2, 3].lazy

slow_proc = ->(n) { sleep(1); n * 2 }

TickTock.wrap_block(subject: "Top Level") do |top_card|
  wrapped_slow_proc = TickTock.wrap_proc(
    subject: ->(n) { "Num: #{n}" },
    &slow_proc
  )

  wrapped_enum = TickTock.wrap_lazy(
    lazy_enum,
    subject: "Lazy Enum",
    parent_card: top_card,
    wrap_card: true
  ).map(&wrapped_slow_proc)

  pp wrapped_enum.to_a
end
