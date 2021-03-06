# coding: utf-8
# Classe destinée à afficher un listing d'un compte entre deux dates
#
# Ce controller peut être sollicité de deux façons.
#
# Méthode 1 : par le menu Listing
# ce qui fait qu'on ne connait pas alors le compte. L'action new est lancée et
# affiche un formulaire permettant de sélectionner les dates et le compte.
#
# Le même mécanisme est lancé par une vue modale.
# Le chemin est alors periods/id/listing
#
# Cela renvoie sur poste/create qui crée le listing et le rend à l'aide de la
# vue show (on aurait pu aussi faire un redirect).
#
# Méthode 2 : Soit par la vue index des comptes ou par une balance.
# Dans ce cas, on connait le compte demandé. Et l'on peut arriver directement
# sur la vue show. Le chemin est alors account/id/listing?
#
# Les exports (pdf, xls, csv) se font par la méthode 2.
#
#
class Compta::ListingsController < Compta::ApplicationController


  include Pdf::Controller
  before_filter :set_exporter, :only=>[:produce_pdf, :pdf_ready, :deliver_pdf]

  # show est appelé directement par exemple par les lignes de la balance
  #  au mpyen de l'icon listing qui apparaît à côté des comptes non vides
  def show
    @account = @period.accounts.find_by_id(params[:account_id])

    unless @account
      # ce cas arrive lorsque l'on change d'exercice alors que l'on est sur la
      # vue show
      # On recopie le flash notice qui indique 'Vous avez changé d'exercice'
      redirect_to(new_compta_period_listing_url(@period),
        notice:flash[:notice]) and return
    end
    @listing = Compta::Listing.new(listing_params)
    @listing.account_id = @account.id


    if @listing.valid?
      calculate_solds(@listing)
      respond_to do |format|

        format.html
        # format.pdf n'existe pas car l'action est produce_pdf
        # qui est assuré par le Pdf::Controller
        format.csv do
          send_export_token
          send_data @listing.to_csv, filename:export_filename(@listing, :csv)
        end  # pour éviter le problème des virgules
        format.xls do
          send_export_token
          send_data @listing.to_xls, filename:export_filename(@listing, :csv)
        end
      end

    else
      render 'new' # le form new affichera Des erreurs ont été trouvées
    end
  end

  # permet de créer un Listing à partir du formualaire qui demande un compte
  # GET periods/listing/new
  def new
    @listing = Compta::Listing.new(from_date:@period.start_date,
      to_date:@period.close_date)
    @listing.account_id = params[:account_id] # permet de préremplir
    # le formulaire avec le compte si on vient de l'affichage
    # du plan comptable (accounts#index)
    @accounts = @period.accounts.order('number ASC')
  end


  # POST periods/listing/create
  # on arrive sur cette actions lorsque l'on remplit le formulaire venant de new
  def create
    @listing = Compta::Listing.new(listing_params)
    @account = @listing.account
    if @listing.valid?
      respond_to do |format|
        format.html {
          redirect_to compta_account_listing_url(@account,
            compta_listing:params[:compta_listing].except(:account_id))
        }
        format.js { calculate_solds(@listing)}# vers fichier create.js.erb
      end
    else
      respond_to do |format|
        format.html { render 'new'}
        format.js {render 'new'} # vers fichier new.js.erb
      end

    end
  end


  protected

  # créé les variables d'instance attendues par le module PdfController
  def set_exporter

    @account = Account.find(params[:account_id])
    logger.debug( "voici le compte trouvé #{@account.inspect}")
    @exporter = @account
    @pdf_file_title = "Listing Cte #{@account.number}"
  end

  # création du job et insertion dans la queue
  def enqueue(pdf_export)
    Delayed::Job.enqueue Jobs::ListingPdfFiller.new(Tenant.current_tenant.id,
      pdf_export.id, {account_id:@account.id,
        params_listing:listing_params})
  end

  def calculate_solds(listing)
    @listing_cumulated_debit_before = listing.solde_debit_avant
    @listing_cumulated_credit_before = listing.solde_credit_avant
    @listing_sold_before = @listing_cumulated_credit_before -
      @listing_cumulated_debit_before
    @listing_total_debit = listing.total_debit
    @listing_total_credit = listing.total_credit
    @listing_cumulated_debit_at = @listing_cumulated_debit_before +
      @listing_total_debit
    @listing_cumulated_credit_at = @listing_cumulated_credit_before +
      @listing_total_credit
    @listing_sold_at = @listing_cumulated_credit_at -
      @listing_cumulated_debit_at

  end

  def listing_params
    params.require(:compta_listing).permit(:from_date_picker, :to_date_picker,
      :from_date, :to_date, :account_id)
  end


end
