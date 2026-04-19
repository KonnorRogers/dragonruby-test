module App
  FPS = 60
end

require "vendor/sprite_kit/sprite_kit.rb"
require "app/game.rb"

def boot(args)
  args.state = {}
end

def tick(args)
  if !args.state.game
    GTK.reset_sprites
    args.state.game = App::Game.new
  end
  args.state.game.tick(args)
end

def reset(args)
  args.state.game = nil

end

GTK.reset
