module App
  module Scenes
    class PlayScene
      attr_accessor :engine
      def initialize
        @engine = Engine.new
      end

      def tick(args)
        @engine.tick(args)
      end
    end
  end
end
