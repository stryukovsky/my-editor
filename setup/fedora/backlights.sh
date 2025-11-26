current=$(light -s sysfs/leds/kbd_backlight)
let inversed=100-${current%.*}
light -s sysfs/leds/kbd_backlight -S $inversed
