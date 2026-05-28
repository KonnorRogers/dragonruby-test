module App
  module Enemies
    ANIMALS_SPRITESHEET = "sprites/32rogues/animals.png"
  end

  ENEMIES = {
    hyena: {
      max_hp: 32,
      hit_box: {
        w: 32,
        h: 18
      },
      animations: {
        idle: {
          source_x: 192,
          source_y: 352,
          source_h: 32,
          source_w: 32,
          path: Enemies::ANIMALS_SPRITESHEET
        }
      }
    }
  }
end
