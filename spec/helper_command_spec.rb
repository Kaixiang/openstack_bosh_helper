require "spec_helper"

describe OpenstackBoshHelper::HelperCommand do
  let(:context) { OpenstackBoshHelper::HelperCommand.new }
  let(:command) { nil }
  let(:inputs) { { :command => 'gm' } }

  subject do
    capture_output { context.stub(:input) { inputs } }
  end

  # TODO: figure out how mothership test looks like

  xit "prompt help msg with help" do
  end

  xit "generate micro bosh deployment after all information provided" do
  end

  xit "deploy micro bosh using micro_bosh deploy cmd" do
  end
end
