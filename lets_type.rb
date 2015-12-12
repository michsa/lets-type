#!/usr/local/bin/ruby

# The much improved Let's Type 2.0

require 'curses'
require 'socket'

class Output  
  def initialize height, width
    @pad = Curses::Pad.new height, width
    @i = 0
    @size = 0
  end

  def print offset
    @pad.refresh offset, 0, HEADER_HEIGHT + 1, 1, MAIN_HEIGHT - 1, MAIN_WIDTH - 1
  end

  def write_center offset, msg
    @pad.setpos offset, 0
    @pad << msg.center(PAD_WIDTH)
  end
  
  def wipe
    @pad.clear
    @size = 0
    @i = 0
    print @i
  end
  
  def scroll input
    case input 
      when Curses::KEY_UP
        @i > 0 and @i -= 1
      when Curses::KEY_DOWN
        @i < @size and @i += 1
    end
    self.print @i
  end
  
  def write input
    string = "#{Time.now.strftime "%H:%M:%S"} <you> #{input}"
    line = ""
    (1..string.length).each do |i|
      line << string[i-1]
      if i % PAD_WIDTH == 0 or i == string.length
        @size += 1
        @i += 1
        @pad.resize PAD_HEIGHT + @size, PAD_WIDTH
        @pad.setpos PAD_HEIGHT + @size - 1, 0
        if line.length % 2 == 0
          @pad.color_set 3
        else 
          @pad.color_set 0
        end
        @pad << line
        line = ""
      end
    end
    self.print @size
  end
end


class Input
  def initialize height, width, y, x
    @win = Curses::Window.new height, width, y, x
    @win.color_set 3
  end

  def refresh
    @win.clear
    @win << " ".center(FOOTER_WIDTH)
    @win.setpos 0, 0
    @win << " > "
    @win.refresh
  end
  
  def win
    return @win
  end
  
  def scroll_mode
    @win.clear
    @win.setpos 0, 0
    @win << "SCROLL MODE".center(FOOTER_WIDTH)
    @win.refresh
  end
end
  
Curses.stdscr.keypad true
Curses.stdscr.nodelay = 1
Curses.init_screen
Curses.start_color
Curses.curs_set 1

WIN_WIDTH = Curses.cols
WIN_HEIGHT = Curses.lines
HEADER_HEIGHT = FOOTER_HEIGHT = 1
MAIN_HEIGHT = WIN_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT
HEADER_WIDTH = FOOTER_WIDTH = MAIN_WIDTH = WIN_WIDTH
PAD_HEIGHT = MAIN_HEIGHT - 2
PAD_WIDTH = MAIN_WIDTH - 2

header_win = Curses::Window.new HEADER_HEIGHT, HEADER_WIDTH, 0, 0
main_win = Curses::Window.new MAIN_HEIGHT, MAIN_WIDTH, HEADER_HEIGHT, 0
footer = Input.new FOOTER_HEIGHT, FOOTER_WIDTH, WIN_HEIGHT - FOOTER_HEIGHT, 0

Curses.init_pair 2, Curses::COLOR_BLACK, Curses::COLOR_GREEN
Curses.init_pair 3, Curses::COLOR_CYAN, Curses::COLOR_BLACK

header_win.color_set 2
header_win << "Let's Type 2.0".center(HEADER_WIDTH)
header_win.refresh

main_win.box ?|, ?-
main_win.refresh

pad = Output.new PAD_HEIGHT, PAD_WIDTH
pad.write_center 0, "Type something and press enter!"
pad.write_center 1, "Enter 'q' to exit. Enter 'c' to clear."
pad.write_center 3, "Enter 's' for SCROLL MODE."
pad.write_center 4, "In SCROLL MODE, use UP and DOWN to scroll."
pad.write_center 5, "Type 'q' or 's' to exit SCROLL MODE."
pad.write_center 7, "Let's Type!! :)"

pad.print 0

footer.refresh

until (input = footer.win.getstr) == 'q'
  if input == 'c'
    pad.wipe
  elsif input == "s"
    footer.scroll_mode
    Curses.raw
    footer.win.keypad true
    until ['q', 's'].include? (scroll_input = footer.win.getch)
      pad.scroll scroll_input
    end
    Curses.noraw
    footer.win.keypad false
  else
    pad.write input
  end
  footer.refresh
end

