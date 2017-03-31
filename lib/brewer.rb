require_relative 'helpers'
require_relative 'adaptibrew'
require_relative 'settings'

include Helpers

class Brewer

  attr_reader :base_path
  attr_accessor :out, :log, :temps

  def initialize
    @base_path = Dir.pwd
    # Output of adaptibrew
    @out = []
    @log = @base_path + '/logs/output'
    @temps = {}
  end

  public

  # Brewer methods ------------------------------------------------------
  # general utilities for the brewer class

  def wait(time=30)
    sleep(time)
    self
  end

  # Sends a slack message in #brewing
  def ping(message="ping at #{Time.now}")
    require_relative 'slacker'
    $slack.ping(message)
  end

  # Only works on Mac :(
  def say(message="done")
    system("say #{message}")
  end

  # Runs an adaptibrew script
  # Output will be stored in @out
  # you may see @out.first quite a bit. This will almost always be directly after calling a script
  # It will be set to the output of the last script. I can't just return the output because i need to return self
  def script(script, params=nil)
    @out.unshift(`python #{@base_path}/adaptibrew/#{script}.py #{params}`.chomp)
    self
  end

  # Clears the @out array
  # Writes current @out to log
  def clear
    write_log(@log, @out)
    @out = []
    self
  end

  # This lil' divider is default for large return blocks
  def echo(string=nil)
    if string == nil
      puts @out.first
    else
      puts string
    end
    self
  end


  # Adaptibrew methods ----------------------------------------------
  # for working with the rig

  def pump(state=0)
    if state == 1
      script("set_pump_on")
    else
      script("set_pump_off")
    end
    self
  end

  def relay(relay, state)
    script("set_relay", "#{relay} #{state}")
    self
  end

  # Turns PID on or off, or gets state if no arg is provided
  def pid(state="status")
    if state == "status"
      echo('----------')
      script("is_pid_running")
      puts "PID is running? " + @out.first
      sv.echo
      pv.echo
    end

    if state == 1
      script('set_pid_on')
      puts "PID is now on"
      pump(1)
      puts "Pump is now on"
    elsif state == 0
      script("set_pid_off")
      puts "PID is now off"
    end

    self
  end

  def all_relays_status
    script("get_relay_status_test")
    puts @out.first.split('\n')
    @out.shift
    self
  end

  def relay_status(relay)
    raise "Relay number needs to be an integer" unless relay.is_a? Integer
    script("get_relay_status", "#{relay}")
    puts @out.first
    self
  end

  def sv(temp=nil)
    if temp
      raise "Temperature input needs to be an integer" unless temp.is_a? Integer
      script('set_sv', temp)
    else
      script('get_sv')
    end
    self
  end

  def pv
    script('get_pv')
    self
  end

  def watch_temp
    until pv.out.first.to_i == sv.out.first.to_i do
      wait(8)
    end
  end

  # WaterVolInQuarts, GrainMassInPounds, GrainTemp, MashTemp
  def get_strike_temp
    print "Input ambount of water in quarts: "
    water = gets.chomp

    print "Input amount of grain in lbs: "
    grain = gets.chomp

    pv.echo
    print "Input current grain temp (return for default above): "
    grain_temp = gets.chomp
    if grain_temp == ""
      grain_temp = pv.out.first.to_i
    end

    print "Input desired mash temp (150): "
    desired_mash_temp = gets.chomp
    if desired_mash_temp == ""
      desired_mash_temp = 150
    end
    @temps['mash'] = desired_mash_temp

    # this is where the magic happens
    script('get_strike_temp', "#{water} #{grain} #{grain_temp} #{desired_mash_temp}")
    @temps['strike_water_temp'] = @out.first.to_i
    sv(@out.first.to_i)
    puts "SV has been set for #{echo} degrees"
    clear
  end

  # Master Procedures -----------------------------------------------------
  # The main steps in the brewing proccess
  def boot
    # These are the states required for starting. Should be called on boot.
    # Print PID status at end
    pid(0).pump(0).relay($settings['rimsToMashRelay'], 1).all_relays_status.pid

    @out.shift(4)
    @out.unshift("Boot successful")
    puts @out[0] + "!"
    self
  end

  def heat_strike_water
    print "Is the strike water in the mash tun? "
    confirm ? nil : abort

    print "Is the return manifold in the mash tun? "
    confirm ? nil : abort

    relay($settings['rimsToMashRelay'], 1)
    puts "RIMS-to-mash relay is now on"

    pump(1)
    puts "Pump is now on"

    puts "Waiting for 30 seconds for strike water to start circulating"
    puts "(ctrl-c to stop now)"
    wait(30)

    print "Is the strike water circulating well? "
    confirm ? nil : abort

    @temps['starting_strike_temp'] = pv.out.first.to_i
    pv
    puts "current strike water temp is #{echo}. Saved."
    puts "Warning: if you exit this brewer shell, the strike water temp will be lost"
    puts ""
    puts "--- Calculate strike temp ---"
    # this sets PID to strike temp
    get_strike_temp
    # turn on pid heater
    # XXX: This?
    pid(1)

    # when strike temp is reached, ping
    watch_temp
    ping("strike water is now at #{pv.echo} degrees")

    self
  end

end
