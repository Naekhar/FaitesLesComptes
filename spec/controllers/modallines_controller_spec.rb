require 'spec_helper'

describe ModallinesController do
  include SpecControllerHelper

  def valid_arguments
    {:book_id=>1, date:Date.today, :narration=>'ligne de test', compta_lines_attributes:{'0' =>{account_id:1, nature_id:2, payment_mode:'Virement', debit:50},
        '1'=>{}}}
  end

  def invalid_arguments
    {:book_id=>1, :narration=>'ligne de test', compta_lines_attributes:{'0' =>{account_id:1, nature_id:2, payment_mode:'Virement', debit:50},
        '1'=>{}}}
  end
  
  before(:each) do
    minimal_instances
    @p.stub(:guess_month).and_return(Date.today.month - 1) 
  end

  describe "POST 'create" do
    it 'should ask for bank_extract, bank_account and organism' do
      BankExtract.should_receive(:find).with("1").and_return(@be = mock_model(BankExtract))
      @be.should_receive(:bank_account).and_return(@ba = mock_model(BankAccount))
      @ba.should_receive(:current_account).with(@p).and_return(mock_model(Account))
      post 'create', {:bank_extract_id=>1, :writing=>valid_arguments}, valid_session
    end
  end

  describe "POST 'create' return success" do

    before(:each) do
      @ba = mock_model(BankAccount)
      @be = mock_model(BankExtract)
      @acc = mock_model(Account)
      @ib = mock_model(IncomeBook)
           
      BankExtract.stub(:find).with(@be.id.to_s).and_return @be
      @be.stub(:bank_account).and_return @ba
     
      @ba.stub(:current_account).with(@p).and_return(@acc)
      @ib.stub(:organism).and_return(@o)
      @o.stub(:find_period).and_return(@p)
      Writing.any_instance.stub(:book).and_return(@ib)
    
      

    end


    it "returns http success with valid arguments" do
      Utilities::NotPointedLines.stub(:new).and_return []
      post 'create', {:format=>:js, :bank_extract_id=>@be.id, :writing=>valid_arguments}, valid_session
      response.should be_success
    end

    it 'should render template create' do
      Utilities::NotPointedLines.stub(:new).and_return []
      post 'create',{ :format=>:js, :bank_extract_id=>@be.id, :writing=>valid_arguments}, valid_session
      response.should render_template 'modallines/create'
    end
    
    it "return also http success with invalid arguments" do
      Utilities::NotPointedLines.stub(:new).and_return []
      post 'create', {:format=>:js, :bank_extract_id=>@be.id, :writing=>invalid_arguments}, valid_session
      response.should be_success
    end

    it 'should render template new when invalid arguments' do
      Utilities::NotPointedLines.stub(:new).and_return []
      post 'create',{ :format=>:js, :bank_extract_id=>@be.id, :writing=>invalid_arguments}, valid_session
      response.should render_template 'modallines/new'
    end



  end

end
