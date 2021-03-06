# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

RSpec.configure do |c|
  # c.filter = {:wip=>true}
end

describe Compta::RubrikParser do 
  include OrganismFixtureBis

  let(:p) {mock_model(Period, 
      :two_period_account_numbers=>%w(12 1201 20 201 2012 206 207 208 2801),
      'previous_period_open?'=>false)}

  describe 'méthode de tri des numéros' do
    
    subject {Compta::RubrikParser.new(p, :actif, '20 !201')}
    
    it 'renvoie les numéros retenus' do
      subject.list_numbers.should == %w(20 206 207 208)
    end

    it 'rubrik_lines' do
      Compta::RubrikLine.stub(:new).and_return 'une rubrique line'
      subject.rubrik_lines.should have(4).rubrik_lines
    end

    it 'raise error si argument mal formé' do
      expect {Compta::RubrikParser.new(p, :actif, '20, 201')}.to raise_error(/argument mal formé/)
    end
  
  end
  
  describe 'Traitement des comptes de résultats : RubrikParser ' do
    
    before(:each) do
      p.stub(:accounts).and_return(@ar = double(Arel))
      p.stub(:resultat).and_return 1234.56
      Compta::RubrikResult.any_instance.stub(:resultat_non_sectorise).and_return 1
   end
    
    it 'renvoie un RubrikResult si le compte est 12' do
      @ar.stub(:find_by_number).and_return(mock_model(Account, number:'12', sold_at:120.54))
      Compta::RubrikParser.new(p, :passif, '12').rubrik_lines.first.
        should be_an_instance_of(Compta::RubrikResult) 
    end
    
    it 'de même pour un compte commençant par 12' do 
      @ar.stub(:find_by_number).and_return(mock_model(Account, number:'1201', sold_at:120.54))
      cr = Compta::RubrikParser.new(p, :passif, '1201')
      # puts cr.inspect  
      cr.rubrik_lines.first.
        should be_an_instance_of(Compta::RubrikResult)
    end
    
    it 'mais pas le 2012' do
      @ar.stub(:find_by_number).and_return(mock_model(Account, number:'2012', sold_at:120.54))
      cr = Compta::RubrikParser.new(p, :passif, '2012')
      # puts cr.inspect  
      expect(cr.rubrik_lines.first).not_to be_an_instance_of(Compta::RubrikResult)
    end
  
  end
  
  describe 'filtre les comptes sur la base du secteur' do
    
    before(:each) do
      @sec1 = mock_model(Sector)
      @acc1 = mock_model(Account, sector_id:@sec1.id, number:'6001')
    end
    
    it 'le folio de secteur 1 a un compte' do
      p.should_receive(:two_period_account_numbers).with(@sec1).and_return(['6001'])
      @rp = Compta::RubrikParser.new(p, :actif, '60', @sec1)
      @rp.list_numbers.should == ['6001']
    end
    
  end
  
end
