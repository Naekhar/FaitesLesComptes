# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper') 

describe Period do
 
  before(:each) do
      @organism= Organism.create(title: 'test asso') 
      @p_2010 = @organism.periods.create!(start_date: Date.civil(2010,04,01), close_date: Date.civil(2010,12,31))
      @p_2011= @organism.periods.create!(start_date: Date.civil(2011,01,01), close_date: Date.civil(2011,12,31))
      @organism.periods.count.should == 2
    end

  context "avec  2 exercices" do 
    
    it 'should respond is_closed when closed' do 
      @p_2010.is_closed?.should be_false
      @p_2010.closable? #.should be_true
      @p_2010.errors[:close].should == [] 
      @p_2010.close
      @p_2010.is_closed?.should be_true
    end 
  end

  context "avec un troisieme exercice" do
    before(:each) do
      @p_2010.close # il faut fermer 2010 pour pouvoir créer 2012
      @p_2012= @organism.periods.create!(start_date: Date.civil(2012,01,01), close_date: Date.civil(2012,12,31))
      @organism.periods.count.should == 3
    end

    describe 'period_next' do
      it "2010 doit repondre 2011" do
        @p_2010.next_period.should == @p_2011
      end
  
      it "2011 doit repondre 2012" do
        @p_2011.next_period.should == @p_2012
      end
      it "2012, le dernier doit repondre lui meme" do
        @p_2012.next_period == @p_2012
      end
    end
  end

  # result est un module qui est destiné à produire les résultats mensuels d'un exercice
  # c'est aussi ce module qui permet de produire les graphiques résultats
  describe "resultat" do
      it "a period can produce a result for each_month" do
        @p_2011.monthly_results.should be_an_instance_of(Array)
        @p_2011.monthly_results.size.should == @p_2011.nb_months
        @p_2010.monthly_results.size.should == @p_2010.nb_months
      end

      it "without datas, a period can produce a monthly result" do
        @p_2010.monthly_result('03-2010').should == 0
      end

    context 'the result is calculated from books' do



      let(:b1) {stub_model(IncomeBook)}
      let(:b2) {stub_model(OutcomeBook)}
     
      P2011_RESULTS = [-5, 10,25,40,55,70,85,100,115,130,145,160]
       P2010_RESULTS = [0,0,0,400, 550, 700, 850, 1000, 1150, 1300, 1450, 1600]
  
 
      before(:each) do

        @p_2011.stub_chain(:books, :all).and_return([b1,b2])
        @p_2010.stub_chain(:books, :all).and_return([b1,b2])
        @p_2011.list_months('%m-%Y').each do |m|
          b1.stub(:monthly_sold).with(m).and_return(100 + 10*(m[/^\d{2}/].to_i) )
          b2.stub(:monthly_sold).with(m).and_return(-120 + 5*(m[/^\d{2}/].to_i) )
        end
        @p_2010.list_months('%m-%Y').each do |m|
          b1.stub(:monthly_sold).with(m).and_return(1000 + 100*(m[/^\d{2}/].to_i) )
          b2.stub(:monthly_sold).with(m).and_return(-1200 + 50*(m[/^\d{2}/].to_i) )
        end
        (1..3).each do |i|
          my="#{format('%02d',i)}-2010" 
          b1.stub(:monthly_sold).with(my).and_return(0)
          b2.stub(:monthly_sold).with(my).and_return(0)
        end
      end

      it "check the monthly result" do 
        @p_2011.monthly_result('03-2011').should == 25
      end

      it 'check_previous_period' do
        @p_2011.previous_period.should == @p_2010
      end

      it 'monthly_results' do
        @p_2011.monthly_results.should == P2011_RESULTS
        @p_2010.monthly_results.should == [400, 550, 700, 850, 1000, 1150, 1300, 1450, 1600]
      end


      it 'have a default graphic method' do
        @p_2011.default_graphic.should be_an_instance_of(Utilities::Graphic) 
      end

      context "check the default graphic" do
        before(:each) do
          @graphic= @p_2011.default_graphic 
        end

        it "should have a legend" do 
          @graphic.legend.should == ['de avr. 2010 à déc. 2010', 'Exercice 2011']
        end
        it "should have two séries" do 
          @graphic.should have(2).series
        end
        it "the first with ..."   do
          b1.monthly_sold('04-2010').should == 1400
          b1.monthly_sold('03-2010').should == 0
          pending 'FIXME problème de stub je pense'
          @graphic.series[0].should == P2010_RESULTS
        end

        it "the second with..." do
          @graphic.series[1].should == P2011_RESULTS
        end

        it "test construction graphique avec un seul exercice"

      end

    end
  end
 
end
