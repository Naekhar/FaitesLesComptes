# coding: utf-8

require 'spec_helper'
require 'pdf_document/page' 


# Ces specs ont essentiellement pour objet de vérifier qu'on peut 
# rendre le pdf 
# Les valeurs sont des fake et il ne faut pas s'attacher à la cohérence
# des montants. 
# Par contre, les totaux, reports et sous totaux doivent être correctement calculés.
#
# La visualisation du fichier pdf se fait par les tests qui sont dans le dossier
# pdf_files
#
describe Editions::Balance do 
  
  def render_file(pdf, file_name) 
    file =  "#{File.dirname(__FILE__)}/test_pdf_files/#{file_name}.pdf"
    File.delete(file) if File.exists?(file)
    File.open(file, 'wb') do |f| 
      f << pdf.render 
    end
  end
  
  class PdfBalanceLine < Struct.new(:number, :title, :cumul_debit_before,
    :cumul_credit_before, :movement_debit, :movement_credit)
  end
  
  def collection
    100.times.collect do |i| 
      PdfBalanceLine.new(
        "#{i}00",
        "Compte n° #{i}",
        0,
        0,
        100,
        0
              )
    end
  end
  
   
  let(:p) {mock_model(Period, organism:double(Organism, title:'Asso test'), long_exercice:'Exercice 2013')}
  let(:source) {double(Object, 
    from_date:Date.today.beginning_of_year,
    to_date:Date.today.end_of_year,
    from_account:'10',
    to_account:'85',
    accounts:collection,
    balance_lines:collection
    )}
  
  
  subject {Editions::Balance.new(p, source, {title:'Balance test'})}
  
  it 'on peut le rendre' do
    expect {subject.render}.not_to raise_error
  end
  
  
  
  
  
end
 