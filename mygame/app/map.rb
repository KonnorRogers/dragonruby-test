module App
  class Map
    # Pack
    def chunk_key(cx, cy)
      (cy << 16) | (cx & 0xFFFF)
    end

    # Unpack (if you ever need to go back)
    def chunk_key_to_cx(key)  (key & 0xFFFF).then { |v| v > 32767 ? v - 65536 : v }  end
    def chunk_key_to_cy(key)  key >> 16  end

    def generate
    end
  end
end
