# Electronic Dice with mruby-esp32
#
# Copyright (c) icm7216 2018
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# [ MIT license: http://www.opensource.org/licenses/mit-license.php ]


include ESP32

class DICE
  attr_accessor :count
  def initialize(count = 10)
    @count = count
    @dice = ["    o    ", "o       o", "o   o   o",
             "o o   o o", "o o o o o", "o oo oo o"]
  end

  def shake(count=@count)
    (1..count).map {Random.rand(6)}
  end
  
  def to_s(count=@count)
    dice_a = self.shake(count).map {|x| @dice[x]}
  end
end

def puts_serial(dice, shake_count)
  shake_count.times do |x|
    puts "Dice count:#{x}", dice[x][0,3], dice[x][3,3], dice[x][6,3] 
  end
end

def puts_oled(dice, oled, time_wait)
  oled.fontsize = 3
  dice.each do |s|
    oled.clear
    oled.rect(38,  4, 52, 60)
    oled.text(42,  2, s[0,3])
    oled.text(42, 20, s[3,3])
    oled.text(42, 38, s[6,3])
    oled.display
    System.delay(time_wait)    
  end
end

# Select output device
serial      = true
SSD1306_i2c = true

# Device config
sw = GPIO::GPIO_NUM_0             # Use the boot switch on board
GPIO.pinMode(sw, GPIO::INPUT)
time_wait = 100                   # OLED wait time, Time unit (m sec).
shake_count = 30                  # Number of Shakes

# Display startup message
if SSD1306_i2c
  i2c = I2C.new(I2C::PORT0, scl: 22, sda: 21).init(I2C::MASTER)
  oled = OLED::SSD1306.new(i2c)
  oled.fontsize = 2
  oled.clear
  oled.text( 15,  0, "mruby-esp32")
  oled.text( 45, 20, "DICE")
  oled.text(  0, 40, "push boot botton")
  oled.display
end

dice = DICE.new(shake_count)
loop do
  if GPIO.digitalRead(sw)==0 
    while GPIO.digitalRead(sw)==0
      dice.shake
    end
    d = dice.to_s
    puts_serial(d, dice.count) if serial
    puts_oled(d, oled, time_wait) if SSD1306_i2c
    GC.start    
  end
end
