defmodule Ssd1306 do
	use GenServer
	use Bitwise

	require Logger

	@moduledoc """
	Handles communicating with the display module.
	"""

  # Constants
  @SSD1306_I2C_ADDRESS    0x3C    # 011110+SA0+RW - 0x3C or 0x3D
  @SSD1306_SETCONTRAST    0x81
  @SSD1306_DISPLAYALLON_RESUME    0xA4
  @SSD1306_DISPLAYALLON    0xA5
  @SSD1306_NORMALDISPLAY    0xA6
  @SSD1306_INVERTDISPLAY    0xA7
  @SSD1306_DISPLAYOFF    0xAE
  @SSD1306_DISPLAYON    0xAF
  @SSD1306_SETDISPLAYOFFSET    0xD3
  @SSD1306_SETCOMPINS    0xDA
  @SSD1306_SETVCOMDETECT    0xDB
  @SSD1306_SETDISPLAYCLOCKDIV    0xD5
  @SSD1306_SETPRECHARGE    0xD9
  @SSD1306_SETMULTIPLEX    0xA8
  @SSD1306_SETLOWCOLUMN    0x00
  @SSD1306_SETHIGHCOLUMN    0x10
  @SSD1306_SETSTARTLINE    0x40
  @SSD1306_MEMORYMODE    0x20
  @SSD1306_COLUMNADDR    0x21
  @SSD1306_PAGEADDR    0x22
  @SSD1306_COMSCANINC    0xC0
  @SSD1306_COMSCANDEC    0xC8
  @SSD1306_SEGREMAP    0xA0
  @SSD1306_CHARGEPUMP    0x8D
  @SSD1306_EXTERNALVCC    0x1
  @SSD1306_SWITCHCAPVCC    0x2

  # Scrolling constants
  @SSD1306_ACTIVATE_SCROLL    0x2F
  @SSD1306_DEACTIVATE_SCROLL    0x2E
  @SSD1306_SET_VERTICAL_SCROLL_AREA    0xA3
  @SSD1306_RIGHT_HORIZONTAL_SCROLL    0x26
  @SSD1306_LEFT_HORIZONTAL_SCROLL    0x27
  @SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL    0x29
  @SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL    0x2A

 	#####
	# External API

	def start_link(width, height, rst, i2c_address \\ @SSD1306_I2C_ADDRESS) do
		GenServer.start_link(__MODULE__, [width, height, rst, i2c_address], name: __MODULE__)
	end

	@doc """
	Clear the screen
	"""
	def clear() do
		GenServer.call __MODULE__, :clear
	end

	@doc """
	Display the screen buffer
	"""
	def display() do
		GenServer.call __MODULE__, :display
	end
  
	@doc """
	Arduino digital write
	"""
	def digital_write(pin, value) do
		GenServer.call(__MODULE__, { :digital_write, pin, value })
	end

	def read(count) do
		GenServer.call(__MODULE__, { :read, count })
	end

 	def write_i2c_block(block) do
 		GenServer.call(__MODULE__, { :write_i2c_block, block})
 	end

	#####
	# GenServer Implementation

  @doc """
  Initialize communications.

  Return the process ID for the I2C process of the board
  """
	def init(width, height, rst, i2c_address) do
		Logger.info "Establishing link to I2C port."
    I2c.start_link("i2c-1", i2c_address)
  end

  def handle_call(:clear, _from, pid) do
		write_i2c_block(pid, <<@firmware_version_cmd, 0, 0, 0>>)
		:timer.sleep(100)
		<<version>> = I2c.read(pid, 1)
		I2c.read(pid, 1)	# Empty the buffer
		{ :reply, version / 10, pid }
	end

	def handle_call(:display, _from, pid) do
    # Write buffer data.
        for i in range(0, len(self._buffer), 16):
            control = 0x40   # Co = 0, DC = 0
            self._i2c.writeList(control, self._buffer[i:i+16])
            
		write_i2c_block(pid, <<@SSD1306_COLUMNADDR, 0, width-1, @SSD1306_PAGEADDR, 0, _pages-1>>)
	end

  def handle_call({:digital_write, pin, value}, _from, pid) do
    { :reply, digitalWrite(pid, pin, value), pid }
  end
  
  def handle_call({:write_i2c_block, block}, _from, pid) do
    { :reply, write_i2c_block(pid, block), pid }
  end

  def handle_call({:read, count}, _from, pid) do
    { :reply, I2c.read(pid, count), pid }
  end

  defp read_i2c_block(pid, count) do
    try do
      I2c.read(pid, count)
    rescue
      IOError -> IO.puts "IOError"; 0
    end
  end

  # Write I2C block
  defp write_i2c_block(pid, block) do
    try do
      :ok = I2c.write(pid, block)
      true	# 1
    rescue
      IOError -> IO.puts "IOError"; false # -1
    end
  end

end
