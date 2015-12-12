#!/usr/local/bin/ruby

require 'curses'
require 'socket'

Curses.stdscr.keypad true
Curses.stdscr.nodelay = 1

Curses.init_screen
Curses.start_color

Curses.curs_set 2

WIN_WIDTH = Curses.cols
WIN_HEIGHT = Curses.lines

HEADER_HEIGHT = 1
HEADER_WIDTH = WIN_WIDTH

FOOTER_HEIGHT = 1
FOOTER_WIDTH = WIN_WIDTH

MAIN_HEIGHT = WIN_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT
MAIN_WIDTH = WIN_WIDTH

TEXT_HEIGHT = MAIN_HEIGHT - 2
TEXT_WIDTH = MAIN_WIDTH - 2

header_win = Curses::Window.new HEADER_HEIGHT, HEADER_WIDTH, 0, 0
main_win = Curses::Window.new MAIN_HEIGHT, MAIN_WIDTH, HEADER_HEIGHT, 0
footer_win = Curses::Window.new FOOTER_HEIGHT, FOOTER_WIDTH, WIN_HEIGHT - FOOTER_HEIGHT, 0

Curses.init_pair 2, Curses::COLOR_BLACK, Curses::COLOR_GREEN

header_win.color_set 2
header_win << "Let's Type".center(HEADER_WIDTH)
header_win.refresh

main_win.box ?|, ?-
main_win.refresh

text_win = main_win.subwin TEXT_HEIGHT, TEXT_WIDTH, HEADER_HEIGHT + 1, 1
text_win.scrollok true
text_win.setpos 0, 0
text_win << "Type something and press enter!".center(TEXT_WIDTH)
text_win.setpos 1, 0
text_win << "Enter 'q' to exit. Enter 'c' to clear.".center(TEXT_WIDTH)
text_win.refresh

text_win.setpos TEXT_HEIGHT - 1, 0

footer_win.color_set 2
footer_win << " ".center(FOOTER_WIDTH)
footer_win.setpos 0, 0

until (input = footer_win.getstr) == 'q'

  text_win << "<#{Time.now.strftime "%H:%M:%S"}> #{input}\r"
  if input == 'c'
    text_win.clear
  end
  text_win.refresh
  text_win.scrl 1
    
  footer_win.clear
  footer_win << " ".center(FOOTER_WIDTH)
  footer_win.setpos 0, 0
  footer_win.refresh
end
