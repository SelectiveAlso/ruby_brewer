require_relative 'spec_helper'

describe Brewer do

  before :each do
    @brewer = Brewer.new
  end

  describe "#new" do
    it "returns a brewer object" do
      expect(@brewer).to be_an_instance_of Brewer
    end
  end

  describe ".wait" do
    # This is kind of iffy like the Helpers#time test
    it "can wait for a number of seconds" do
      #  not using let(:current_time) etc. because
      # the var is created upon the first calling, which is in the expect()
      current_time = Time.now.to_i
      @brewer.wait(1)
      expect(current_time + 1).to eq(Time.now.to_i)
    end
  end

  describe ".script" do
    it "can run a python script and get output" do
      @brewer.script('python_tester')
      expect(@brewer.out.first).to eq("it worked")
    end
  end

  describe ".clear" do
    context "when there is output" do
      let(:brewer) { Brewer.new }
      before { brewer.script('python_tester') }
      specify { expect(brewer.out.first).to eq("it worked") }

      it "can clear the output" do
        @brewer.clear
        expect(@brewer.out).to be_empty
      end
    end
  end

end