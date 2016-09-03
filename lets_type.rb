#!/usr/local/bin/ruby

# The much improved Let's Type 2.0

require 'curses'
require 'socket'

class Output  
  def initialize height, width
    @pad = Curses::Pad.new height, width
    @i = 0
    @size = 0
    @make_log = true
    @log = "lets_type_#{Time.now.strftime "%Y-%m-%d_%H-%M-%S"}.txt"
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
        @pad.color_set 3
        @pad << line
        if @make_log
          f = File.open(@log, "a")
          f.puts line
          f.close
        end
        line = ""
      end
    end
    self.print @size
  end
  
  def push_up lines
    self.print @size + lines
  end
  
  def toggle_logging
    @make_log = !@make_log
  end
end


class Input
  def initialize height, width, y, x
    @win = Curses::Window.new height, width, y, x
    @win.color_set 0
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
  
end

constants = Array.new
Curses::Key.constants.each do |constant|
  constants.push Curses::Key.const_get constant
end
  
Curses.stdscr.keypad true
Curses.stdscr.nodelay = 1
Curses.init_screen
Curses.start_color
Curses.curs_set 1

WIN_WIDTH = Curses.cols
WIN_HEIGHT = Curses.lines
HEADER_HEIGHT = 1
curr_footer_height = FOOTER_HEIGHT = 1
MAIN_HEIGHT = WIN_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT
HEADER_WIDTH = FOOTER_WIDTH = MAIN_WIDTH = WIN_WIDTH
PAD_HEIGHT = MAIN_HEIGHT - 2
PAD_WIDTH = MAIN_WIDTH - 2

header = Curses::Window.new HEADER_HEIGHT, HEADER_WIDTH, 0, 0
main = Curses::Window.new MAIN_HEIGHT, MAIN_WIDTH, HEADER_HEIGHT, 0
footer = Input.new FOOTER_HEIGHT, FOOTER_WIDTH, WIN_HEIGHT - FOOTER_HEIGHT, 0

Curses.init_pair 2, Curses::COLOR_BLACK, Curses::COLOR_GREEN
Curses.init_pair 3, Curses::COLOR_CYAN, Curses::COLOR_BLACK

header.color_set 2
header << "Let's Type 2.0".center(HEADER_WIDTH)
header.refresh

main.box ?|, ?-
main.refresh

pad = Output.new PAD_HEIGHT, PAD_WIDTH
pad.write_center 0, "Type something and press enter!"
pad.write_center 2, "Use arrow keys to scroll."
pad.write_center 1, "Enter '/q' to exit. Enter '/c' to clear."
pad.write_center 4, "Let's Type!! :)"

pad.print 0

footer.refresh
line = ''
n = 0
max_n = 0
footer.win.keypad true
  
while (input = footer.win.getch)
  if footer.win.curx == WIN_WIDTH - 1
    curr_footer_height += 1
    main.resize MAIN_HEIGHT + 1 - curr_footer_height, MAIN_WIDTH
    main.box ?|, ?-
    main.refresh
    pad.push_up curr_footer_height - FOOTER_HEIGHT
    footer.win.move WIN_HEIGHT - curr_footer_height, 0
    footer.win.resize curr_footer_height, FOOTER_WIDTH
  end
  if input == 10
    if line == '/c'
      pad.wipe
    elsif line == '/q'
      break
    elsif line == '/l'
      pad.toggle_logging
    else
      pad.write line
    end
    line = ''
    n = max_n = 0
    curr_footer_height = FOOTER_HEIGHT
    footer.win.resize FOOTER_HEIGHT, FOOTER_WIDTH
    footer.win.move WIN_HEIGHT - FOOTER_HEIGHT, 0
    footer.refresh
    main.resize MAIN_HEIGHT, MAIN_WIDTH
    main.box ?|, ?-
    main.refresh
    pad.push_up 0
  elsif input == Curses::KEY_UP or input == Curses::KEY_DOWN
    pad.scroll input
  elsif input == Curses::KEY_BACKSPACE and n > 0
    footer.win.delch
    line.slice! n-1
    n -= 1
    max_n -= 1
  elsif input == Curses::KEY_LEFT and n > 0
    footer.win.setpos footer.win.cury, footer.win.curx-1
    n -= 1
  elsif input == Curses::KEY_RIGHT and n < max_n
    footer.win.setpos footer.win.cury, footer.win.curx+1
    n += 1
  elsif !constants.include? input
    if n < max_n
      footer.win.insch line[n]
    end
    line.insert n, input
    n += 1
    max_n += 1
  end
end
