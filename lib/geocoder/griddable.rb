require 'geocoder'

module Geocoder
  class Griddable
    module KmToLong
      extend self
      include Math
      R = 6_371 #km
      def coord_to_km(coord1, coord2)
        lat1 = deg_to_rad(coord1.lat)
        lat2 = deg_to_rad(coord2.lat)
        dlat = deg_to_rad(coord2.lat - coord1.lat)
        dlng = deg_to_rad(coord2.lng - coord1.lng)

        a = sin(dlat/2)**2 + sin(dlng/2)**2 * cos(lat1) * cos(lat2)
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        R*c
      end

      def km_per_one_lng(coord)
        coord1 = coord
        coord2 = coord.dup
        coord2.lng += 1
        coord_to_km(coord1, coord2)
      end

      def km_per_one_lat
        coord1 = Struct.new(:lat, :lng).new(10,10)
        coord2 = coord1.dup
        coord2.lat+=1
        coord_to_km(coord1, coord2)
      end

      def km_to_lat(km)
        km / km_per_one_lat
      end

      def km_to_lng(km, coord)
        km / km_per_one_lng(coord)
      end

      def deg_to_rad(num)
        num * PI / 180
      end
    end
    include KmToLong

    Point = Struct.new(:lat, :lng) do
      def initialize(*args)
        if args.size == 1 && args[0].is_a?(String)
          args = args[0].split(',').map(&:to_f)
        end
        super
      end

      def to_s
        "#{lat},#{lng}"
      end
    end

    Grid = Struct.new(:lines) do
      def to_s
        lines.to_s
      end

      def to_json
        lines.flatten.map do |l|
          l.to_s.split(',').map(&:to_f)
        end.to_json
      end
    end

    class Line
      attr_accessor :startc, :endc
      def initialize(*args)
        @startc, @endc = args[0] > args[1] ? [args[1], args[0]] : args
      end

      def length
        (@endc - @startc).abs
      end

      def divide_by(number)
        dx = length / number
        (@startc..@endc).step(dx).to_a
      end
    end

    attr_reader :top_left, :bottom_right, :options, :unfiltered_grid
    attr_accessor :cache

    def initialize(opts)
      @top_left = Point.new(opts.fetch(:top_left))
      @bottom_right = Point.new(opts.fetch(:bottom_right))
      @options = {}
      @options[:rule] = opts.fetch(:rule)
      @options[:name] = opts.fetch(:name) if opts[:rule] == 'country'
    end
    
    def to_grid(km)
      y = get_y_divider(km)
      return unless y
      lines = vertical_divisions(y).map do |lat|
        x = get_x_divider(km, lat)  
        horizontal_divisions(x).map do |lng|
          Point.new(lat, lng)
        end
      end
      @unfiltered_grid = grid = Grid.new(lines)
      filter_grid(grid)
    end

    private

    def by_country(coord)
      res = ((self.cache ||= {})[coord] ||= Geocoder.search(coord.to_s))

      res && 
        res[0] && 
        res[0].country.downcase.eql?(options[:name].downcase)
    end

    def within?(point)
      case options[:rule]
      when "country"
        by_country(point)
      end
    end

    def top_right
      @top_right ||= Point.new(top_left.lat, bottom_right.lng)
    end

    def bottom_left
      @bottom_left ||= Point.new(bottom_right.lat, top_left.lng)
    end

    def get_y_divider(km)
      ((top_left.lat - bottom_left.lat) / km_to_lat(km)).round
    end

    def get_x_divider(km, lat)
      ((top_right.lng - top_left.lng) / km_to_lng(km, Point.new(lat, 10))).round
    end

    def vertical_divisions(divider)
      Line.new(top_left.lat, bottom_left.lat).divide_by(divider)
    end

    def horizontal_divisions(divider)
      Line.new(top_left.lng, top_right.lng).divide_by(divider)
    end

    def filter_grid(grid)
      grid.lines = grid.lines.dup.map do |line|
        line.select! do |point|
          within?(point)
        end
        line.reject(&:nil?) if line.any?
      end.reject(&:nil?)
      grid
    end
  end
end
