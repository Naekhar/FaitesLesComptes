# -*- encoding : utf-8 -*-

class InOutWritingsController < ApplicationController 
 
  # TODO voir pour utiliser ChangePeriod plutôt que check_if_has_changed_period
  # ce qui permettrait probablement de ne pas surcharger fill_mois

  before_filter :find_book # remplit @book
  before_filter :fill_mois, only: [:index, :new]
  before_filter :check_if_has_changed_period, only: :index # car on peut changer de period quand on clique sur une
  # des barres du graphe.qui est affiché par organism#show
  before_filter :fill_natures, :only=>[:new,:edit] # pour faire la saisie des natures en fonction du livre concerné

  # GET /in_out_writings
  # TODO changer @monthly_extract en @extract
  def index
    if params[:mois] == 'tous'
      @monthly_extract = Extract::InOut.new(@book, @period)
    else
      @monthly_extract = Extract::MonthlyInOut.new(@book, year:params[:an], month:params[:mois])
    end
    send_export_token
    respond_to do |format|
      
      format.html  # index.html.erb
      format.pdf { send_data @monthly_extract.to_pdf.render, :filename=>export_filename(@book, :pdf) }
      format.csv { send_data @monthly_extract.to_csv, :filename=>export_filename(@book, :csv)  } 
      format.xls { send_data @monthly_extract.to_xls, :filename=>export_filename(@book, :csv) }
    end
  end

  # GET /in_out_writings/new
  def new
    @in_out_writing =@book.in_out_writings.new(date: flash[:date] || @monthyear.guess_date)
    @line = @in_out_writing.compta_lines.build
    @counter_line = @in_out_writing.compta_lines.build
    if flash[:previous_line_id]
      @previous_line = ComptaLine.find_by_id(flash[:previous_line_id])
      @line.payment_mode = @previous_line.payment_mode
    end
    
  end


  # POST /lines
  # POST /lines.json
  def create
    fill_counter_line
    @in_out_writing = @book.in_out_writings.build(params[:in_out_writing])
    @line = @in_out_writing.in_out_line
    @counter_line=@in_out_writing.counter_line
    
    respond_to do |format|
      if @in_out_writing.save
        flash[:date]=@in_out_writing.date # permet de transmettre la date à l'écriture suivante
        flash[:previous_line_id]=@line.id
        
        mois = sprintf('%.02d',@in_out_writing.date.month); an = @in_out_writing.date.year
        format.html { 
          if flash[:retour] && flash[:retour] =~ /pointage\z/
            redirect_to flash[:retour]
          else
            redirect_to new_book_in_out_writing_url(@book, mois:mois, an:an) 
          end 
          }
      else
        Rails.logger.warn("erreur dans create_line")
        Rails.logger.warn(@in_out_writing.errors.messages)
        Rails.logger.warn(@counter_line.inspect)
        fill_natures
        format.html { render action: "new" }

      end
    end
  end
  
  
  # méthode expérimentale pour utiliser les actions cachées
  # actuellement la vue affiche création du fichier en cours.
  # 
  # Idée générale : on stocke le fichier dans une table avec différents champs
  # un champ blob pour la page, évidemment un champ organism_id, un champ catégory
  # pour enregistrer le type de documents (voir avec une STI ?), par exemple compte bancaire
  # un champ pdf_able_id et pdf_able_type, ce qui permet de le faire appartenir à un
  # modèle qui serait alors pdf_able.
  # evidemment un timestamp. 
  # 
  # Eventuellement cela permet de vérifier que le fichier est toujours d'actualité si 
  # aucune écriture nouvelle n'a été passée concernant le compte bancaire en question.
  # (mais dans un deuxième temps)
  # 
  # Il faut alors que le job fasse la création du fichier puis quand il est fait 
  # qu'il le sauve dans la base correcte.
  # 
  # Dans le même temps, il faut déclencher un timer qui va sonder régulièrement
  # par une requete ajax si le fichier est prêt. 
  # 
  # On pourrait avoir dans la table User (ou Organisme) un champ qui indique le début du travail
  # , puis la fin et l'id du pdf qui vient d'être généré.
  #  Plutôt une table spécifique ? Ou directement la table sachant qu'on connaît la catégorie
  #  d'objet demandé (par exemple une balance).
  #  
  #  Il faudrait commencer par essayer la logique de ce stockage
  #  
  #  Dans l'immédiat j'ai fait une table exportpdfs et son modèle Exportpdf
  #  avec un seul champ content. (limité à 1 méga). TODO voir à augmenter cette limite si nécessaire
  #  
  #  Dans un premier temps, un seul fichier par organisme. 
  # 
  #
  def export_pdf
    if params[:mois] == 'tous'
      @monthly_extract = Extract::InOut.new(@book, @period)
    else
      @monthly_extract = Extract::MonthlyInOut.new(@book, year:params[:an], month:params[:mois])
    end
    
    # création du record export_pdf
    # @monthly_extract.delay.render_pdf
  end

  
  

  # flash[:origin] et la méthode comes_from permet de déterminer la route à reprendre 
  # lorsqu'on sera dans update. Soit on vient de index et y retourne. Soit on vient 
  # de new mais on a fait une modif lors de la saisie et on retourne alors dans new
  def edit
    flash[:origin] = comes_from
    @in_out_writing = @book.in_out_writings.find(params[:id])
    @line = @in_out_writing.in_out_line
    @counter_line = @in_out_writing.counter_line
  end



  # PUT /lines/1
  # PUT /lines/1.json
  def update
    actio = flash[:origin] || 'index'
    @in_out_writing = @book.in_out_writings.find(params[:id])
    @line = @in_out_writing.in_out_line
    @counter_line = @in_out_writing.counter_line
    fill_counter_line
    respond_to do |format|
      if @in_out_writing.update_attributes(params[:in_out_writing])
        mois = sprintf('%.02d',@in_out_writing.date.month); an =  @in_out_writing.date.year
        format.html { redirect_to url_for(book_id:@book.id, action:actio, mois:mois, an:an) }#], notice: 'Line was successfully updated.')}
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @line.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lines/1
  # DELETE /lines/1.json
  def destroy
    @w = @book.in_out_writings.find(params[:id])
    my = MonthYear.from_date(@w.date)
    if @w.destroy
      flash[:notice] = 'L\'écriture a été détruite'
    else
      flash[:alert] = 'Une anomalie est survenue, l\'écriture n\'a pu être détruite'
    end

    respond_to do |format|
      format.html { redirect_to book_in_out_writings_url(@book, :mois=>my.month, :an=>my.year) }
      format.json { head :ok }
    end
  end

  protected

  # permet de savoir si on vient d'une action new
  # utilisé par edit pour remplir un flash qui sera à son tour utilisé par update.
  def comes_from
    request.env['HTTP_REFERER'][/(\w*)\?/]
    @origin = ($1 == 'new') ? 'new' : 'index'
  end


  # complète les informations pour la counter_line en remplissant les
  # champs débit et crédit à partir du champ de la compta_line
  def fill_counter_line
      p  = params[:in_out_writing][:compta_lines_attributes]
      p['1'][:credit] = p['0'][:debit] || 0
      p['1'][:debit]= p['0'][:credit] || 0
      
  end


  # Initie la variable d'instance book
  def find_book
    @book = Book.find(params[:book_id] || params[:income_book_id] || params[:outcome_book_id] )
  end

  
  # TODO ici il faut remplacer cette méthode par une méthode period.natures_for_book(@book) qui choisira les natures qui
  # conviennent à la classe du livre.
  def fill_natures
    if @book.class.to_s == 'IncomeBook'
      @natures=@period.natures.recettes
    elsif @book.class.to_s == 'OutcomeBook'
      @natures=@period.natures.depenses
    end
  end

  # on surcharge fill_mois pour gérer le params[:mois] 'tous'
  def fill_mois
    if params[:mois] == 'tous'
      @mois = 'tous'
      @monthyear= @period.guess_month
    else
      super
    end
  end


  # check_if_has_changed_period est rendu nécessaire car on peut accéder directement aux lignes d'un exercice
  # à partir du graphe d'accueil et donc via l'action index.
  #
  # @monthyear est défini dès lors que le params[:mois] est différent de 'tous'
  # Mais si le paramètre est 'tous', alors il ne peut y avoir de changement d'exercice.
  #
  def check_if_has_changed_period
    # si le month_year demandé ne fait pas partie de l'exercice,
    if @monthyear && !@period.list_months.include?(@monthyear)
      # voit si on peut trouver l'exercice ad hoc
      @new_period = @organism.guess_period(@monthyear.beginning_of_month)
      if @new_period
        flash[:alert]= "Attention, vous avez changé d'exercice !"
        my = @new_period.guess_month(@monthyear.beginning_of_month) # car si les exercices ne sont pas de même durée,
        # on pourrait tomber dans un exercice qui n'existe pas
        session[:period] = @new_period.id
        redirect_to url_for(mois:my.month, an:my.year, :format=>params[:format])
      else
        flash[:alert] = "Le mois et l'année demandés ne correspondent à aucun exercice"
        redirect_to :back
      end
    end

  end



end
