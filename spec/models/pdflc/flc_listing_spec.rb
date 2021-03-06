#coding: utf-8

require 'spec_helper'

RSpec.configure do |c|
  # c.filter = {:wip=>true}
end

describe Pdflc::FlcListing do


  def render_file(pdf, file_name)
    file =  "#{File.dirname(__FILE__)}/pdf_files/#{file_name}.pdf"
    File.delete(file) if File.exists?(file)
    File.open(file, 'wb') do |f|
      f << pdf.render
    end
  end


  # ['w_id', 'w_date', 'b_abbreviation', 'w_ref', 'w_narration',
  #    'nat_name', 'dest_name', 'debit', 'credit']
  def twenty_two_lines
    22.times.collect do |i|
      double(ComptaLine,

        w_date:Date.today,
        w_piece_number:11,
        b_abbreviation:'AB',
        w_ref:nil,
        w_narration:'Ecriture',
        nat_name:'nature',
        dest_name:'destination',
        debit:0,
        credit:(i+1)*1.10)

    end
  end

  # on a deux pages  par compte et 22 lignes à chaque fois
  before(:each) do
    Tenant.set_current_tenant(1)
    @fas = Account.new(number:'123456', title:'Le compte à essayer à tout prix')
    Pdflc::FlcTable.any_instance.stub(:nb_pages).and_return 2
    Pdflc::FlcTable.any_instance.stub(:lines).and_return twenty_two_lines

    Account.any_instance.stub(:period).and_return(@p = double(Period,
      organism:double(Organism, title:'Asso Essai'),
      long_exercice:'Exercice 2014'))
    Account.any_instance.stub(:cumulated_at).and_return 0


  end

  # le pdf fera 8 pages, 2 pages pour chacun des comptes sauf pour le second
  # qui n'a pas de lignes.
  it 'peut rendre le texte avec un fond', wip:true  do
    @b = Pdflc::FlcListing.new(from_account:@fas,
    from_date:Date.today.beginning_of_year,
    to_date:Date.today.end_of_year,
    fond:'Mise au point')
    @b.draw_pdf
  #  render_file(@b.pdf, 'listing')
  end

  it 'peut rendre le texte pour un exercice décalé' do
    @p.stub(:long_exercice).and_return "Exercice \nsept. 2014 à août 2018"
    @b = Pdflc::FlcListing.new(from_account:@fas,
    from_date:Date.today.beginning_of_year,
    to_date:Date.today.end_of_year,
    fond:'Mise au point')
    @b.draw_pdf
    render_file(@b.pdf, 'listing')

  end

end
