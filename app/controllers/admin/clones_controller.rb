# clones_controller permet de produire un clone d'une base de données pour faire
# une version de secours avant une opération spécifique, par exemple avant de passer
# les écritures d'inventaire ou encore avant de clôre un exercice
#
# Le commentaire qui sera rentré dans le formulaire affiché par la vue new, servira de
# commentaire pour la nouvelle room
#
class Admin::ClonesController < Admin::ApplicationController

  skip_before_filter :current_period

  before_filter :owner_only

  after_filter :clear_org_cache, only:[:create]

  # ici on a besoin que d'un formulaire qui donne un organism avec son champ commentaire
  def new
    @new_clone = Organism.new
  end

  # @organism est fourni par le before_filter find_organism
  def create
    ucl = Utilities::Cloner.create(:old_org_id=>@organism.id)
    if ucl && new_id = ucl.clone_organism(admin_cloner_params[:comment])
      # l'organisme est créé. Reste à créer son holder.
      Holder.create(user_id:current_user.id, organism_id:new_id,
                    status:'owner', tenant_id:Tenant.current_tenant.id) # car seul le owner est habilité (voir le before_filter)
      flash[:notice] = 'Un clone de votre base a été créé'
    else
      flash[:alert] = 'Une erreur s\'est produite lors de la création du clone de votre base'
    end
    redirect_to admin_organisms_url
  end

  protected

  # les actions ne sont permises que si le current_user est le owner
  def owner_only
    unless current_user == @organism.owner
      flash[:alert] = "Vous ne pouvez executer cette action car vous n'êtes pas le propriétaire de la base"
      redirect_to admin_organisms_url
    end

  end

  def admin_cloner_params
    params.require(:organism).permit(:comment)
  end
end
