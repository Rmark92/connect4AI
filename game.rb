require_relative 'board'
require_relative 'player'
require_relative 'move_search'

class Game
  def initialize
    welcome_prompt
    name = retrieve_player_name
    @human = Human.new(name)
    @computer = Computer.new('BeepBoop')
    @scoreboard = { @human => 0, @computer => 0 }
  end

  def welcome_prompt
    system 'clear'
    puts 'Welcome to Connect 4!'
    puts
  end

  def retrieve_player_name
    puts 'Please enter your name'
    name = nil
    loop do
      name = gets.chomp
      break unless name.empty?
      puts 'Sorry, you must enter something for your name'
    end
    puts
    name
  end

  def set_marker_preference
    options = Board::MARKERS.map { |marker| "'#{marker.to_s.downcase}'" }.join(' or ')
    puts "Type either #{options} to choose your marker ('x' goes first)"
    marker_pref = nil
    loop do
      marker_pref = gets.chomp.upcase.to_sym
      break if Board::MARKERS.include?(marker_pref)
      puts "Sorry, you must choose either #{options}"
    end
    puts
    @human.marker = marker_pref
    @computer.marker = Board.other_marker(marker_pref)
    @current_player = @human.marker == :X ? @human : @computer
  end

  def set_difficulty_preference
    range_vals = "#{Computer::THINKING_TIME_RANGE.min} and #{Computer::THINKING_TIME_RANGE.max}"
    puts "Type a number between #{range_vals} to set the computer thinking time (in seconds)"
    puts '(more thinking time yields a logarithmic increase in difficulty)'
    difficulty_pref = nil
    loop do
      difficulty_pref = gets.chomp.to_f
      break if Computer::THINKING_TIME_RANGE.cover?(difficulty_pref)
      puts "Sorry, you must enter a number between #{range_vals}"
    end
    puts
    @computer.thinking_time = difficulty_pref
  end

  def switch_turns
    @current_player = (@current_player == @human ? @computer : @human)
  end

  def turn
    system 'clear'
    @board.draw
    @current_player.make_move(@board)
    sleep(2)
  end

  def play
    loop do
      round
      display_scoreboard
      break unless player_continues?
    end
    puts 'Thanks for playing!'
  end

  def player_continues?
    puts "Would you like to play another round? ('y' or 'n')"
    ans = nil
    loop do
      ans = gets.chomp.downcase[0]
      break if ans && ['y', 'n'].include?(ans)
    end
    ans == 'y'
  end

  def round
    @board = Board.new
    set_marker_preference
    set_difficulty_preference
    puts "Great! Let's gets started..."
    sleep(2)
    result = nil
    loop do
      turn
      result = detect_game_result
      result ? break : switch_turns
    end
    display_result(result)
    update_scoreboard(result)
  end

  def display_result(result)
    system 'clear'
    @board.draw
    case result
    when :winner
      puts "#{@current_player.name} wins the game!"
    when :tie
      puts "It's a tie!"
    end
    puts
  end

  def detect_game_result
    if @board.four_connected?(@current_player.marker)
      :winner
    elsif @board.full?
      :tie
    end
  end

  def update_scoreboard(result)
    @scoreboard[@current_player] += 1 if result == :winner
  end

  def display_scoreboard
    scoreboard_str = @scoreboard.map { |player, score| "#{player.name} => #{score}" }
                                .join(' | ')
    puts 'SCOREBOARD'.center(scoreboard_str.size)
    puts '-' * scoreboard_str.size
    puts scoreboard_str
    puts
    sleep(2)
  end
end

Game.new.play
