# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.configure do |c|  
#  c.filter = {wip:true}
#  c.filter = {:js=> true }
#  c.exclusion_filter = {:js=> true } 
end

# spec request for testing admin cashes

describe 'admin cash' do
  include OrganismFixtureBis 
  
  
  before(:each) do
    create_user
    use_test_organism
    login_as('quidam')
    
  end

  describe 'new cash' do
    before(:each) do
      visit new_admin_organism_cash_path(@o)
    end


    it "affiche la page new" do
      current_url.should match new_admin_organism_cash_path(@o)
      page.should have_content("Nouvelle caisse")
      all('form div.control-group').should have(3).elements # name, comment et sector
      
    end
    
    it 'il y a une caisse' do
      @o.cashes.count.should == 1
    end

    it 'remplir correctement le formulaire cree une nouvelle ligne', wip:true do
      
      fill_in 'cash[name]', :with=>'Entrepôt'
      # save_and_open_page
      click_button "Créer la caisse" # le compte' 
      #
      @o.cashes.count.should == 2
#      current_url.should match admin_organism_cashes_path(@o)
#      all('tbody tr').should have(2).rows
      
    end

    context 'remplir incorrectement le formulaire' do
    it 'test uniqueness organism, name, number' do
     
      fill_in 'cash[name]', :with=>@c.name
      click_button "Créer la caisse" # le compte'
      page.should have_content('déjà utilisé')
      @o.should have(1).cashes
    end 

    it  'test presence name' do
      visit new_admin_organism_cash_path(@o)
      click_button "Créer la caisse" # le compte'
      page.should have_content('obligatoire')
    end

    end


  end
 
  describe 'index' do

   
    it 'on peut le choisir dans la vue index pour le modifier' do
      
      visit admin_organism_cashes_path(@o)
      click_link "icon_modifier_cash_#{@c.id.to_s}"
      current_url.should match(edit_admin_organism_cash_path(@o,@c))
    end

  end

  describe 'edit' do

    it 'On peut changer les deux autres champs et revenir à la vue index' do
      
      visit edit_admin_organism_cash_path(@o, @c)
      fill_in 'cash[name]', :with=>'Entrepôt'
      click_button 'Enregistrer'
      current_url.should match admin_organism_cashes_path(@o)
      find('tbody tr:last-child td:first-child').text.should == 'Entrepôt'

      
    end

  end


end

