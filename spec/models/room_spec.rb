# -*- encoding : utf-8 -*-
require 'spec_helper'

RSpec.configure do |c| 
  # c.filter = {wip:true}
end

describe Room  do
  include OrganismFixtureBis   

  let(:u) {stub_model(User)}

  def valid_attributes
    {database_name:'foo'}
  end

  before(:each) do
    Apartment::Database.reset
  end

  it 'test de l existence des bases'  do
    Apartment::Database.db_exist?('public').should == true
  end

  describe 'les validations' do

    before(:each) do
      Room.any_instance.stub(:user).and_return u
    end

    it 'has a user' do
      Room.new.should_not be_valid
    end

    it 'has a database_name' do
      u.rooms.new.should_not be_valid
    end

    it 'database_name is composed of min letters without space - les chiffres sont autorisés mais pas en début' do
      val= ['nom base', 'Nombase', '1nom1base', 'nombase%']
      val.each do |db_name|
        u.rooms.new(database_name:db_name).should_not be_valid
      end
      u.rooms.new(database_name:'unnomdebasecorrect').should be_valid
      u.rooms.new(database_name:'unnom2basecorrect').should be_valid
    end

    it 'le nom est strippé avant la validation' do
      u.rooms.new(database_name:'  unnomdebasecorrect  ').should be_valid
    end

    it 'save crée la base si elle n existe pas' do
      unnom = 'unnomdebasecorrect'
      r = u.rooms.new(database_name:unnom)
      
      Apartment::Database.drop(unnom) if Apartment::Database.db_exist?(unnom)
      r.save
      Apartment::Database.db_exist?(unnom).should == true
    end

    it 'le nom de base doit être unique'  do
      Apartment::Database.drop('foo') if Apartment::Database.db_exist?('foo')
      u.rooms.find_or_create_by_database_name('foo')
      r = u.rooms.new(valid_attributes)
      r.should_not be_valid
      r.errors.messages[:database_name].should == ['déjà utilisé']
    end

  end

  describe 'methods' do

    before(:each) do
      @r = Room.new(:database_name=>'foo')
    end


    it 'la base est en retard si organism_migration est inférieure à room' do
      omv = Organism.migration_version
      @r.stub(:look_for).and_return omv
      Room.should_receive(:jcl_last_migration).and_return(omv+1)
      @r.relative_version.should == :late_migration
    end
    
    it 'en phase si les deux migrations sont égales' do
      omv = Organism.migration_version
      @r.stub(:look_for).and_return omv
      Room.stub(:jcl_last_migration).and_return(omv)
      @r.relative_version.should == :same_migration
    end
    
    it 'en avance si organism_migration est supérieure à celle de room' do
      omv = Organism.migration_version
      @r.stub(:look_for).and_return omv
      Room.stub(:jcl_last_migration).and_return(omv-1)
      @r.relative_version.should == :advance_migration
    end

    it 'et renvoie no_base si elle n est pas trouvée' do
      @r.stub(:look_for).and_return nil
      @r.relative_version.should == :no_base
    end
 
    it 'sait répondre aux questions late?, no_base? et advance_migration?' do
      @r.stub(:relative_version).and_return :late_migration
      @r.should be_late
      @r.stub(:relative_version).and_return :advance_migration
      @r.should be_advanced
      @r.stub(:relative_version).and_return :no_base
      @r.should be_no_base
    end

  end

  describe 'tools' do
    before(:each) do
      create_user 
    end

    describe 'connnect_to_organism'  do
      it 'connect_to_organism retourne true si la base existe' do
        @r.connect_to_organism.should be_true
      end

      it 'appelle Apartment.reset si le fichier n est pas trouvé' do
        @r.database_name = nil
        @r.connect_to_organism
        base = case ActiveRecord::Base.connection_config[:adapter]
        when 'sqlite3' then 'test'
        when 'postgresql' then 'public'
        else
          'inconnu'
        end
        Apartment::Database.current.should == base 
      end
     
    end    

    describe 'look_for' do

      it 'retourne la valeur demandée par le bloc'  do
        Organism.should_receive(:first).and_return('Voilà')
        @r.look_for {Organism.first}.should == 'Voilà'
      end


    end

    describe 'organism' do
      it 'retourne l organisme correspondant à cette base' do
        Organism.stub(:first).and_return('un organisme')
        @r.organism.should == 'un organisme'
      end
    end

    describe 'gestion des schemas', wip:true  do
      before(:each) do
        create_user
        create_organism
        Apartment::Database.switch('public')
      end

     

      it 'un changement de nom de base doit appeler change_schema_name' do
        @r.database_name = 'newvalue'
        @r.should_receive(:change_schema_name).exactly(2).times
        @r.save
        @r.database_name = 'assotest1'
        @r.save
      end

      it 'un changement de nom de base doit appeler change_schema_name' do
        @r.created_at = Time.now
        @r.should_not_receive(:change_schema_name)
        @r.save
      end

      it 'met à jour le champ database_name de organsim' do
        
        Apartment::Database.switch('public')
        @r.database_name = 'changedvalue'
        @r.save!
        @r.organism.database_name.should == 'changedvalue'
        @r.database_name = 'assotest1' 
        @r.save
      end

      it 'si un changement échoue, l organisme est inchangé' do
        @r.database_name = 'changed_value' # le soulignement est interdit
        @r.save
        @r.reload
        @r.organism.database_name.should == 'assotest1'
      end

    end


    
  end

  describe 'version_update'  do 

   it 'version_update? est capable de vérifier la similitude des versions' do
      ActiveRecord::Migrator.any_instance.stub(:pending_migrations).and_return ['quelquechose']
      Room.should_not be_version_update
    end

    it 'version_update? retourne true s il n y a pas de migration en attente' do
      ActiveRecord::Migrator.any_instance.stub(:pending_migrations).and_return []
      Room.should be_version_update
    end


  end

    

  describe 'verification des bases après les tests de room' do

    it 'la base assotest1 doit exister' do
      Apartment::Database.db_exist?('assotest1').should be_true
    end


  end
end
