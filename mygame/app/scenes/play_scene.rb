module App
  module Scenes
    class PlayScene
      def initialize
        @engine = Engine.new
      end

      def tick(args)
        @engine.tick(args)
      end
    end
  end
end
