# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

RSpec.configure do |c|
#  c.filter = {:js=> true }
#  c.exclusion_filter = {:js=> true }
end

# spec request for testing admin cashes

describe 'admin cash' do
  include OrganismFixture
  
  
  before(:each) do
    clean_test_database
    Cash.count.should == 0
    create_minimal_organism 
  end

  it 'check minimal organism' do
    Organism.count.should == 1
    Cash.count.should == 0
 end

  describe 'new bank_account' do
    before(:each) do
      visit new_admin_organism_cash_path(@o)
    end


    it "affiche la page new" do
      current_url.should match new_admin_organism_cash_path(@o)
      page.should have_content("Nouvelle caisse")
      all('form div.control-group').should have(2).elements # name et comment
      
    end

    it 'remplir correctement le formulaire cree une nouvelle ligne' do
      
      fill_in 'cash[name]', :with=>'Magasin'
      
      click_button "Créer la caisse" # le compte'
      current_url.should match admin_organism_cashes_path(@o)
      all('tbody tr').should have(1).rows 
      
    end

    context 'remplir incorrectement le formulaire' do
    it 'test uniqueness organism, name, number' do
      @o.cashes.create!(name: 'Magasin')
      fill_in 'cash[name]', :with=>'Magasin'
      click_button "Créer la caisse" # le compte'
      page.should have_content('déjà utilisé')
      @o.should have(1).cashes
    end 

    it  'test presence name' do
      visit new_admin_organism_cash_path(@o)
      click_button "Créer la caisse" # le compte'
      page.should have_content('champ obligatoire')
    end

    end


  end
 
  describe 'index' do

    it 'dans la vue index,une caisse peut être détruit', :js=>true do
      @o.cashes.create!(:name=>'Magasin')
      @o.should have(1).cashes
      # à ce stade chacun des livres est vierge et peut donc être détruit.
      visit admin_organism_cashes_path(@o)
      all('tbody tr').should have(1).rows
      within 'tbody tr:nth-child(1)' do
        page.should have_content('Magasin')
        page.click_link 'Supprimer'
      end
      alert = page.driver.browser.switch_to.alert
      alert.accept
      sleep 1     
      all('tbody tr').should be_empty #_not have(0).elements
 
    end

    it 'on peut le choisir dans la vue index pour le modifier' do
      @ca = @o.cashes.create!(:name=>'Magasin')
      visit admin_organism_cashes_path(@o)
      click_link "icon_modifier_cash_#{@ca.id.to_s}"
      current_url.should match(edit_admin_organism_cash_path(@o,@ca))
    end

  end

  describe 'edit' do

    it 'On peut changer les deux autres champs et revenir à la vue index' do
      @ca = @o.cashes.create!(:name=>'Magasin')
      visit edit_admin_organism_cash_path(@o, @ca)
      fill_in 'cash[name]', :with=>'Entrepôt'
      click_button 'Enregistrer'
      current_url.should match admin_organism_cashes_path(@o)
      find('tbody tr td').text.should == 'Entrepôt'

      
    end

  end


end
