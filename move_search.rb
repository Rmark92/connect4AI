class MoveSearch
  COLUMN_ORDER = (0...Board::NUM_COLS).sort_by { |idx| (Board::NUM_COLS / 2 - idx).abs }
  attr_reader :evaluated_positions, :max_depth

  def initialize(board, marker, thinking_time)
    @board = board
    @marker = marker
    @ttable = {}
    @max_depth = 0
    @evaluated_positions = 0
    @empty_squares = @board.empty_squares
    @end_time = Time.now + thinking_time
    search
  end

  def search
    until Time.now > @end_time || @max_depth >= @empty_squares
      @max_depth += 1
      alpha_beta(@board, @marker, -Float::INFINITY, Float::INFINITY, @max_depth)
    end
  end

  def best
    (@ttable[@board.hash] && @ttable[@board.hash][:best_move]) ||
    random_move
  end

  def alpha_beta(board, marker, alpha, beta, depth)
    return :early_exit if Time.now > @end_time
    @evaluated_positions += 1
    entry = @ttable[board.hash]

    if entry && entry[:depth] >= depth
      case entry[:type]
      when :exact
        return entry[:score]
      when :lower
        alpha = [entry[:score], alpha].max
      when :upper
        beta = [entry[:score], beta].min
      end
      return entry[:score] if alpha >= beta
    end

    other_marker = Board.other_marker(marker)
    max_score = 70**2 - (@max_depth - depth)

    if board.four_connected?(other_marker)
      store_result(board.hash, -max_score, alpha, beta, depth, nil)
      return -max_score
    elsif board.full?
      store_result(board.hash, 0, alpha, beta, depth, nil)
      return 0
    elsif depth.zero?
      score = board.evaluate_position(marker)
      store_result(board.hash, score, alpha, beta, depth, nil)
      return score
    end

    best_score = -max_score - 1
    best_move = nil

    if entry && entry[:best_move]
      column_order = [entry[:best_move]] + (COLUMN_ORDER - [entry[:best_move]])
    else
      column_order = COLUMN_ORDER
    end

    column_order.each do |column|
      board.next_idx[column] ? board.make_move!(column, marker) : next
      result = alpha_beta(board, other_marker, -beta, -alpha, depth - 1)
      board.unmake_move!(column, marker)
      return :early_exit if result == :early_exit
      score = -result
      if score > best_score
        best_score = score
        best_move = column
        alpha = [best_score, alpha].max
      end
      break if best_score >= beta
    end

    store_result(board.hash, best_score, alpha, beta, depth, best_move)
    best_score
  end


  def store_result(hash, result, alpha, beta, depth, best_move)
    if result <= alpha
      @ttable[hash] = { score: result, type: :lower, depth: depth, best_move: best_move }
    elsif result >= beta
      @ttable[hash] = { score: result, type: :upper, depth: depth, best_move: best_move }
    else
      @ttable[hash] = { score: result, type: :exact, depth: depth, best_move: best_move }
    end
  end

  def random_move
    COLUMN_ORDER.select { |column| @board.next_idx[column] }
                .sample
  end
end
