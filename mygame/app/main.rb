module App
  FPS = 60

  def self.current_time_ms
    (Time.now.to_f * 1000).to_i
  end
end

require "vendor/sprite_kit/sprite_kit.rb"
require "app/extended_geometry.rb"
require "app/ui/indicators/arc_indicator.rb"
require "app/spells.rb"
require "app/enemies.rb"
require "app/animation_mixin.rb"
require "app/ui.rb"
require "app/ui/radial_menu.rb"
require "app/ui/circle.rb"
require "app/ui/attack_circle.rb"
require "app/ui/on_screen_joystick.rb"
require "app/ui/bar.rb"
require "app/ui/floating_text.rb"
require "app/ui/frame.rb"
require "app/character.rb"
require "app/enemy.rb"
require "app/player.rb"
require "app/map.rb"

# Always last
require "app/engine.rb"
require "app/scenes/play_scene.rb"
require "app/game.rb"

module Main
  def tick(args)
    if !@game
      GTK.reset_sprites
      @game ||= App::Game.new
    end

    @game.tick(args)
  end

  def reset(args)
    GTK.reset_sprites
    @game = nil
  end
end

DR.reset
