# -*- encoding : utf-8 -*-

class Admin::OrganismsController < Admin::ApplicationController

  class NomenclatureError < StandardError; end

  skip_before_filter :find_organism, :current_period, only:[:index, :new] 
  before_filter :use_main_connection, only:[:index, :new, :destroy]

  after_filter :clear_org_cache, only:[:create, :update]

  
  # GET /organisms/1
  # GET /organisms/1.json
  def show
    # @organism et @period sont définis par les before_filter
    unless @period
      flash[:alert]= 'Vous devez créer un exercice pour cet organisme'
      redirect_to new_admin_organism_period_url(@organism)
      return
    end
    # on trouve l'exercice à partir de la session mais si on a changé d'organisme
    # session[:period] aura été mis à nil
    # il faut alors charger le dernier exercice par défaut et l'affecter à la session
    #    begin
    #      @period = @organism.periods.find(session[:period])
    #    rescue
    #      @period = @organism.periods.last
    #      session[:period]=@period.id
    #    end
    #
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @organism }
    end
  end

  # GET /organisms/new
  # GET /organisms/new.json
  def new
    @organism = Organism.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @organism }
    end
  end

  # GET /organisms/1/edit
  def edit
    @organism = Organism.find(params[:id])
  end

  # POST /organisms
  # POST /organisms.json
  def create
    errors = nil
    @organism = Organism.new(params[:organism])

    # vérifie que le fichier de base de données n'existe pas
    if File.exist? @organism.full_name
      errors= 'Le fichier existe déja; Si vous voulez travailler avec ce fichier, vous devez restaurer l\'organism par le menu Restauration'
      @organism.errors.add(:base, 'fichier déja présent')
    end
    

    if @organism.valid?
      # on crée une room pour le user qui a créé cette base
      @room = current_user.rooms.new(:database_name => params[:organism][:database_name])
      if @room.save
        @organism.create_db
        @room.connect_to_organism # normalement inutile car create_db reste sur la toute nouvelle base
        @organism.save
        session[:org_db]  = @organism.database_name
        redirect_to new_admin_organism_period_url(@organism), notice: "Création de l'organisme effectuée, un livre des recettes et un livre des dépenses ont été créés.\n
          Il vous faut maintenant créer un exercice pour cet organisme"
      else
        errors = 'Impossible de créér cette base, le nom n\'est pas valable ou est déja utilisé'
      end
    else
      errors = 'Impossible de créer l\'organisme'
    end
    if errors
      flash[:alert]= errors
      render :new
    end
   
  end

  # PUT /organisms/1
  # PUT /organisms/1.json
  def update
    @organism = Organism.find(params[:id])

    respond_to do |format|
      if @organism.update_attributes(params[:organism])

        format.html { redirect_to [:admin, @organism], notice: "Modification de l'organisme effectuée" }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @organism.errors, status: :unprocessable_entity }
      end
    end
  end



#  # DELETE /organisms/1
#  # DELETE /organisms/1.json
#  def destroy
#    @organism = Organism.find(params[:id])
#    if @organism.destroy
#      session[:period] = session[:org_db] = nil
#
#
#      redirect_to admin_organisms_url
#    else
#      render
#    end
#
#  end

  protected

  
   # appelé par after_filter pour effacer les caches utilisés pour l'affichage
   # des menus
   def clear_org_cache
     Rails.cache.clear("saisie_#{current_user.name}")
     Rails.cache.clear("admin_#{current_user.name}")
     Rails.cache.clear("compta_#{current_user.name}")
   end

 
end
