# -*- encoding : utf-8 -*-
class Admin::AccountsController < Admin::ApplicationController
  # GET /compta/accounts
  # GET /compta/accounts.json
  def index
    @compta_accounts = @period.accounts.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @compta_accounts }
    end
  end

  # GET /compta/accounts/1
  # GET /compta/accounts/1.json
  def show
    @account = Account.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account }
    end
  end

  # GET /compta/accounts/new
  # GET /compta/accounts/new.json
  def new
    @account = @period.accounts.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @compta_account }
    end
  end

  # GET /compta/accounts/1/edit
  def edit
    @account = Account.find(params[:id])
  end

  # POST /compta/accounts
  # POST /compta/accounts.json
  def create
    @account = @period.accounts.new(params[:account])

    respond_to do |format|
      if @account.save
        format.html { redirect_to admin_organism_period_accounts_path(@organism,@period), notice: 'Le compte a été créé.' }
        format.json { render json: @account, status: :created, location: @account }
      else
        format.html { render action: "new" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /compta/accounts/1
  # PUT /compta/accounts/1.json
  def update
    @account = @period.accounts.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html {
          if @organism.all_natures_linked_to_account?(@period)
          redirect_to admin_organism_period_accounts_path(@organism,@period), notice: 'Le compte a été mis à jour'
          else
            flash[:alert]= 'Toutes les natures ne sont pas reliées à des comptes'
            way = @organism.array_natures_not_linked(@period).first.income_outcome ? 'incomes' : 'outcomes'
            redirect_to modify_mapping_admin_organism_period_accounts_path(@organism,@period,type: way)
            end

            }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /compta/accounts/1
  # DELETE /compta/accounts/1.json
  def destroy
    @compta_account = Account.find(params[:id])
    @compta_account.destroy

    respond_to do |format|
      format.html { redirect_to admin_organism_period_accounts_url(@organism,@period) }
      format.json { head :ok }
    end
  end

  def modify_mapping
    if params[:type]== 'incomes'
    @accounts=@period.accounts.classe_7
    @unlinked_natures=@organism.natures.recettes.reject {|r| r.linked_to_account?(@period) }
    elsif params[:type]== 'outcomes'
    @accounts=@period.accounts.classe_6
    @unlinked_natures=@organism.natures.depenses.reject {|r| r.linked_to_account?(@period) }
    else
     redirect_to mapping_admin_organism_period_accounts_url(@organism,@period)
    end
  end

  def mapping
    @accounts=@period.accounts
    @unlinked_natures=@organism.array_natures_not_linked(@period)
  end
end
