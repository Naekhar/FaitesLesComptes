# -*- encoding : utf-8 -*-


class PeriodsController < ApplicationController



  # GET /periods
  # GET /periods.json
  def index
    @periods = @organism.periods.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @periods }
    end
  end

  def previous
    @period=Period.find(params[:id]).previous_period
    session[:period]=@period.id
    redirect_to :back
  end

  def next
    @period=Period.find(params[:id]).next_period
    session[:period]=@period.id
    redirect_to :back
  end

  

end
