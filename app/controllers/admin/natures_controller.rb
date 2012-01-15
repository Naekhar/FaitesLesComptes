# -*- encoding : utf-8 -*-

class Admin::NaturesController < Admin::ApplicationController

  

  # GET /natures
  # GET /natures.json
  def index
    @recettes = @period.natures.recettes
    @depenses = @period.natures.depenses

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @natures }
    end
  end

 

 
  # GET /natures/new
  # GET /natures/new.json
  def new
    @nature = @period.natures.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @nature }
    end
  end

  # GET /natures/1/edit
  def edit
#    @period=Period.find(params[:period_id])
    @nature = @period.natures.find(params[:id])
  end

  # POST /natures
  # POST /natures.json
  def create
    @nature = @period.natures.new(params[:nature])

    respond_to do |format|
      if @nature.save
        format.html { redirect_to admin_organism_period_natures_path(@organism, @period), notice: 'La Nature a été créée.' }
        format.json { render json: @nature, status: :created, location: @nature }
      else
        format.html { render action: "new" }
        format.json { render json: @nature.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /natures/1
  # PUT /natures/1.json
  def update
    @nature = @period.natures.find(params[:id])

    respond_to do |format|
      if @nature.update_attributes(params[:nature])
        format.html { redirect_to admin_organism_period_natures_path(@organism, @period), notice: 'Nature a été mise à jour.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @nature.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /natures/1
  # DELETE /natures/1.json
  def destroy
    @nature = @period.natures.find(params[:id])
    @nature.destroy

    respond_to do |format|
      format.html { redirect_to admin_organism_period_natures_url(@period) }
      format.json { head :ok }
    end
  end
end
