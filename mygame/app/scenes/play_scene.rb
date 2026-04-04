module App
  module Scenes
    class PlayScene
      def tick(args)
        args.outputs.primitives << {
          **App::ENEMIES.hyena.idle,
          x: Grid.w / 2,
          y: Grid.h / 2,
          w: 32 * 2,
          h: 32 * 2,
          primitive_marker: :sprite
        }
      end
    end
  end
end
