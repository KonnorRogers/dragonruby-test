module App
  FPS = 60
end

require "vendor/sprite_kit/sprite_kit.rb"
require "app/game.rb"

def tick(args)
  args.state.game ||= App::Game.new
  args.state.game.tick(args)
end

def reset(args)
  args.state.game = nil
end

GTK.reset
