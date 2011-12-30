# -*- encoding : utf-8 -*-

class LinesController < ApplicationController

  layout :choose_layout

  before_filter :find_book,   :current_period
  before_filter :fill_mois, only: [:index, :new, :create]

  # GET /lines
  # GET /lines.json
  def index
    

    fill_soldes


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @lines }
    end
  end


  # appelé par l'icone clé dans l'affichage des lignes pour
  # verrouiller la ligne concernée.
  # la mise à jour de la vue est faite par lock.js.erb qui
  # cache les icones modifier et delete, ainsi que l'icone clé et
  # fait apparaître l'icone verrou fermé.
  #  def lock
  #    @line=Line.find(params[:id])
  #    if @line.update_attribute(:locked, true)
  #      respond_to do |format|
  #        format.js # appelle validate.js.erb
  #      end
  #    end
  #  end

 

  # GET /lines/new
  # GET /lines/new.json
  def new
    @line =@book.lines.new(line_date: flash[:date] || Date.today, :cash_id=>@organism.cashes.first.id, :bank_account_id=>@organism.bank_accounts.first.id)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @line }
      
    end
  end
  
  # POST /lines
  # POST /lines.json
  def create
    flash[:date]= get_date
    @line = @book.lines.new(params[:line])
     
    respond_to do |format|
      if @line.save
        mois=(@line.line_date.month)-1
        format.html { redirect_to new_book_line_url(@book,mois: mois), notice: 'La ligne a été créée.' }


        format.js do
          fill_soldes
          render :redirect
        end # redirection via js
        format.json { render json: @line, status: :created, location: @line }
      else
        format.html { render action: "new" }
        format.json { render json: @line.errors, status: :unprocessable_entity }
        format.js 
      end
    end
  end

  # PUT /lines/1
  # PUT /lines/1.json
  #  def update
  #    @line = @book.lines.find(params[:id])
  #
  #
  #    respond_to do |format|
  #      if @line.update_attributes(params[:line])
  #        mois=(@line.line_date.month) -1
  #        format.html { redirect_to book_lines_url(@book, mois: mois) }#], notice: 'Line was successfully updated.')}
  #        format.json { head :ok }
  #      else
  #        format.html { render action: "edit" }
  #        format.json { render json: @line.errors, status: :unprocessable_entity }
  #      end
  #    end
  #  end

  # DELETE /lines/1
  # DELETE /lines/1.json
  #  def destroy
  #    @line = @book.lines.find(params[:id])
  #    @line.destroy
  #
  #    respond_to do |format|
  #      format.html { redirect_to book_lines_url(@book) }
  #      format.json { head :ok }
  #    end
  #  end

  protected
  def find_book
    @book=Book.find(params[:book_id] || params[:income_book_id] || params[:outcome_book_id] )
    @organism=@book.organism
  end

  def fill_mois
    @mois = params[:mois] || @period.guess_month
  end

  
  def choose_layout
    (request.xhr?) ? nil : 'application'
  end

  def fill_soldes
    @date=@period.start_date.months_since(@mois.to_i)
   
    @lines = @book.lines.mois(@date).all
    @solde_debit_avant=@book.lines.solde_debit_avant(@date)
    @solde_credit_avant=@book.lines.solde_credit_avant(@date)

    @total_debit=@lines.sum(&:debit)
    @total_credit=@lines.sum(&:credit)
    @solde= @solde_credit_avant+@total_credit-@solde_debit_avant-@total_debit
  end

  def get_date
    params[:line][:line_date]= picker_to_date(params[:pick_date_line])
  end



end
