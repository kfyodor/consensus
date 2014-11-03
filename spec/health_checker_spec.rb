require 'spec_helper'

describe Consensus::HealthChecker::HealthReport do
  subject { described_class.new 4 }

  it 'increments' do
    expect { subject.inc! }.to change(subject, :ticks_count).by 1
  end

  it 'reports' do
    subject.report!(1)
    expect(subject.report).to eq Hash[0, 1]
  end

  context 'backlog' do
    before do
      5.times do
        subject.inc!
        subject.report!(1)
      end
    end

    it 'has correct range start' do
      expect(subject.send :range_start).to eq 1
    end

    it 'has correct range end' do
      expect(subject.send :range_end).to eq 4
    end

    it 'has correct backlog' do
      expect(subject.send :backlog).to eq [1,1,1,1]
    end
  end
end