# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.configure do |config|
  #  config.filter =  {wip:true}
end


describe  NatureObserver do
  include OrganismFixture


    let(:cl1) { mock_model(ComptaLine, :account_id=>1) }
    let(:cl2) { mock_model(ComptaLine, :account_id=>1) }



  before(:each) do

    @nature = Nature.new(name:'ecolo', :account_id => 1)
    @nature.period_id = 1
    
    @nature.stub(:compta_lines).and_return([cl1, cl2])

    
  end
  
  
  describe 'after_save' do

    it 'identifie les lignes qui sont rattachées à cette nature' do
      @nature.should_receive(:compta_lines).and_return([cl1,cl2])
      [cl1, cl2].each {|l| l.stub(:update_attributes)}
      @nature.save
    end

    it 'modifie le account_id des lignes dépendant de nature' do
      @nature.account_id = 3
      cl1.should_receive(:update_attributes).with(:account_id=>3)
      cl2.should_receive(:update_attributes).with(:account_id=>3)
      @nature.save
      
    end

   


  end
  
end 
