# coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

#RSpec.configure do |c|
  #  c.filter = {:js=> true }
  # c.filter = { :wip=>true}
  #  c.exclusion_filter = {:js=> true } 
#end


describe 'resquest admin archive' do    
  include OrganismFixture

  before(:each) do

    create_user
    create_minimal_organism  
    login_as('quidam')
  end


  describe 'create archive' do  

    it 'afficher la vue de organisme puis cliquer sur l icone sauvegarder renvoie sur la vue archive new' do
      visit admin_organism_path(@o)
      click_link("Fait une sauvegarde de toutes les données de l'organisme")
      page.find('.champ h3').should have_content "Création d'un fichier de sauvegarde"
      # current_url.should match new_admin_organism_archive_path(@o)
    end

    it 'remplir la vue et cliquer sur le bouton propose de charger un fichier' do
      visit new_admin_organism_archive_path(@o)
      fill_in 'archive[comment]', :with=>'test archive'
      
      click_button 'new_archive_button'
      name = "assotest1 #{I18n.l Time.now}"
      # pour éviter d'avoir des erreurs liées à un changement de seconde
      # pendant le test, on isole le dernier chiffre et on crée une expression
      # régulière
      filename = name[0,name.length-2]+'[0-5][0-9]'+'.sqlite3'
      cd = page.response_headers['Content-Disposition']
      cd[/attachment; filename=(.*)/]
      $1.should match filename # contrôle du titre du fichier
      
    end



  end


end
