# -*- encoding : utf-8 -*-
class Admin::CashesController < Admin::ApplicationController



  # GET /cashes 
  # GET /cashes.json
  def index
    @cashes = @organism.cashes 

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @cashes }
    end
  end


  # GET /cashes/new
  # GET /cashes/new.json
  def new
    @cash = @organism.cashes.new
    @cash.sector_id = @organism.sectors.first.id unless @organism.sectored?

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @cash }
    end
  end

  # GET /cashes/1/edit
  def edit
    @cash = @organism.cashes.find(params[:id])
  end

  # POST /cashes
  # POST /cashes.json
  def create
    @cash = @organism.cashes.new(cash_params)

    respond_to do |format|
      if @cash.save
        format.html { redirect_to admin_organism_cashes_url(@organism), notice: 'La caisse a été créée' }
        format.json { render json: @cash, status: :created, location: @cash }
      else
        format.html { render action: "new" }
        format.json { render json: @cash.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /cashes/1
  # PUT /cashes/1.json
  def update
    @cash = @organism.cashes.find(params[:id])

    respond_to do |format|
      if @cash.update_attributes(cash_params)
        format.html { redirect_to admin_organism_cashes_url(@organism), notice: 'La caisse a été modifiée.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @cash.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cashes/1
  # DELETE /cashes/1.json
#  def destroy
#    @cash = @organism.cashes.find(params[:id])
#    @cash.destroy
#
#    respond_to do |format|
#      format.html { redirect_to admin_organism_cashes_url(@organism) }
#      format.json { head :ok }
#    end
#  end

  private
  
  def cash_params
    params.require(:cash).permit(:name, :comment, :sector_id, :organism_id)
  end
end
