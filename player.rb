class Player
  attr_reader :name
  attr_accessor :marker

  def initialize(name)
    @name = name
  end
end

class Human < Player
  def make_move(board)
    loop do
      puts 'Please select a column (Enter a number 1-7)'
      column = gets.chomp.to_i
      error = move_choice_error(board, column)
      if error
        puts error
      else
        puts "#{name} places in column #{column}"
        board.make_move!(column - 1, marker)
        break
      end
    end
  end

  def move_choice_error(board, column)
    if !(1..7).cover?(column)
      "Sorry, that number's out of range"
    elsif board.next_idx[column - 1].nil?
      "Sorry, that column's full!"
    end
  end
end

class Computer < Player
  THINKING_TIME_RANGE = (0.1..30.0)
  attr_writer :marker, :thinking_time

  def make_move(board)
    print "#{name}'s thinking..."
    move_search = MoveSearch.new(board, marker, @thinking_time)
    move = move_search.best
    board.make_move!(move, marker)
    2.times { puts }
    puts "After looking #{move_search.max_depth} moves ahead "\
         "and considering #{move_search.evaluated_positions} positions,"
    puts "#{name} places in column #{(move) + 1}"
    sleep(1)
  end
end
