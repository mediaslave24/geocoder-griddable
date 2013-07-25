## geocoder-griddable gem

Usage:

``` ruby
settings = {
  top_left: "44.370987,22.313232", 
  bottom_right: "40.763901,29.53125",
  rule: "country",
  name: "bulgaria"
}

griddable = Geocoder::Griddable.new(settings)
grid = griddable.to_grid(50) # km's
```
