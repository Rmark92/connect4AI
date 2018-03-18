class Board
  # Board positions for each player will be represented by a 48-bit number
  # with the position of those bits corresponding to the following display:
  # (the bits in the top row (6, 13, etc) will always be 0)

  # 6 13 20 27 34 41
  # 5 12 19 26 33 40 47
  # 4 11 18 25 32 39 46
  # 3 10 17 24 31 38 45
  # 2  9 16 23 30 37 44
  # 1  8 15 22 29 36 43
  # 0  7 14 21 28 35 42

  FULL_BOARD = 0b111111011111101111110111111011111101111110111111
  NUM_COLS = 7
  NUM_ROWS = 7
  HORIZONTAL = NUM_COLS
  VERTICAL = 1
  DIAG_UP_RIGHT = HORIZONTAL + VERTICAL
  DIAG_DOWN_LEFT = HORIZONTAL - VERTICAL
  MAX_IDX = NUM_COLS * NUM_ROWS - 1
  LIMITS = (5..MAX_IDX).step(NUM_ROWS).to_a
  MARKERS = [:X, :O]
  ZOBRIST_IDXS = { O: 0, X: 1 }

  # The max evaluated position value is 69**2 since
  # there are 69 ways to connect 4 pieces on the board,
  # so we set our winning move value to 70**2

  WINNING_POSITION_VAL = 70**2

  attr_reader :next_idx, :positions, :hash

  def initialize
    @positions = { X: 0b0, O: 0b0 }
    @next_idx = (0..MAX_IDX).step(NUM_ROWS).to_a
    @ztable = create_zobrist_table
    @hash = rand(2**64)
  end

  def evaluate_position(marker)
    open_winning_positions(marker)**2 - open_winning_positions(Board.other_marker(marker))**2
  end

  def open_winning_positions(marker)
    non_blocked = FULL_BOARD ^ @positions[Board.other_marker(marker)]
    [HORIZONTAL, VERTICAL, DIAG_UP_RIGHT, DIAG_DOWN_LEFT].inject(0) do |total_count, shift|
      shifted = (non_blocked & (non_blocked >> shift))
      shifted2 = shifted & (shifted >> shift * 2)
      total_count + shifted2.to_s(2).count('1')
    end
  end

  def draw
    display_arr = create_display_arr
    puts
    display_arr.each do |row|
      puts ' ||' + row.join('|') + '||'
    end
    puts ' ' * 2 + '=' + (['='] * 7).join('=') + '='
    puts ' ' * 3 + (1..7).to_a.join(' ')
  end

  def make_move!(col, marker)
    idx = @next_idx[col]
    @positions[marker] |= (2**idx)
    @next_idx[col] = LIMITS[col] == idx ? nil : idx + 1
    @hash ^= @ztable[idx][ZOBRIST_IDXS[marker]]
  end

  def unmake_move!(col, marker)
    @next_idx[col] = @next_idx[col].nil? ? LIMITS[col] : @next_idx[col] - 1
    @positions[marker] ^= (2 ** @next_idx[col])
    @hash ^= @ztable[@next_idx[col]][ZOBRIST_IDXS[marker]]
  end

  def four_connected?(marker)
    positions = @positions[marker]
    [HORIZONTAL, VERTICAL, DIAG_UP_RIGHT, DIAG_DOWN_LEFT].any? do |shift|
      shifted = (positions & (positions >> shift))
      shifted > 0 && (shifted & (shifted >> shift * 2)) > 0
    end
  end

  def full?
    ((@positions[:X] | @positions[:O]) ^ FULL_BOARD).zero?
  end

  def empty_squares
    ((@positions[:X] | @positions[:O]) ^ FULL_BOARD).to_s(2).count('1')
  end

  def self.other_marker(marker)
    (MARKERS - [marker]).first
  end

  private

  def create_display_arr
    display_arr = Array.new(NUM_ROWS - 1).map { Array.new(NUM_COLS, '_') }
    @positions.each do |marker, positions|
      idx = 0
      until positions.zero?
        if positions | (2 ** idx) == positions
          col, row = idx.divmod(NUM_COLS)
          display_arr[-(row + 1)][col] = marker.to_s
          positions ^= (2 ** idx)
        end
        idx += 1
      end
    end
    display_arr
  end

  def create_zobrist_table
    z_table = []
    for piece_pos in (0..MAX_IDX)
      z_table[piece_pos] = [rand(2**64), rand(2**64)]
    end
    z_table
  end
end
