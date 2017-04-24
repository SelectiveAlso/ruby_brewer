require_relative 'spec_helper'

describe Brewer do
  before :each do
    @brewer = Brewer::Brewer.new
  end

  before :all do
    Brewer::Adaptibrew.new.refresh
  end

  after :all do
    # in case something goes wrong, everything needs to be reset
    @brewer = Brewer::Brewer.new
    @brewer.pump(0)
    @brewer.pid(0)
  end

  describe ".pump" do
    # If the pump is already on it does nothing
    it "turns the pump on" do
      expect(@brewer.pump(1)).to eq("pump on")
    end

    # If the pump is already off it does nothing
    it "turns the pump off" do
      expect(@brewer.pump(0)).to eq("pump off")
    end

    it "returns the pump status" do
      expect(@brewer.pump).to be_an_instance_of String
    end

    # cant really test this one...
    context "when the pid is also on" do
      # This turns on both pump and pid
      before { @brewer.pid(1) }
      it "turns the pump and pid off" do
        expect(@brewer.pump(0)).to eq("pump off")
      end
    end
  end

  describe ".relay" do
    it "turns the relay on" do
      expect(@brewer.relay(2, 1)).to be true
    end

    it "turns the relay off" do
      expect(@brewer.relay(2, 0)).to be true
    end
  end

  describe ".pid" do
    it "turns the pid on" do
      expect(@brewer.pid(1)).to eq("Pump and PID are now on")
    end

    it "turns the pid off" do
      expect(@brewer.pid(0)).to eq("PID off")
    end

    it "returns the pid status" do
      expect(@brewer.pid).to be_an_instance_of Hash
    end
  end

  describe ".sv" do
    context "when there is no argument" do
      it "returns the sv temp" do
        expect(@brewer.sv).to be_an_instance_of Float
      end
    end

    context "when there is an argument" do
      it "sets the sv temp" do
        expect(@brewer.sv(150)).to be_an_instance_of Float
      end
    end
  end

  describe ".pv" do
    it "returns the pv" do
      expect(@brewer.pv).to be_an_instance_of Float
    end
  end

  describe ".relay_status" do
    it "returns the status of a relay" do
      @brewer.relay($settings['rimsToMashRelay'], 1)
      expect(@brewer.relay_status($settings['rimsToMashRelay'].to_i)).to eq("on")
      @brewer.relay($settings['rimsToMashRelay'], 0)
      expect(@brewer.relay_status($settings['rimsToMashRelay'].to_i)).to eq("off")
    end
  end

  describe ".relays_status" do
    it "returns the status of the 4 main relays" do
      statuses = @brewer.relays_status
      expect(statuses).to be_an_instance_of Hash
      expect(statuses).to_not be_empty
      expect(statuses['spargeRelay']).to be_an_instance_of String
    end
  end

  describe ".status_table" do
    it "returns a current status table" do
      expect(@brewer.status_table).to be_an_instance_of Terminal::Table
    end
  end

  describe ".relay_config" do
    
  end

end
