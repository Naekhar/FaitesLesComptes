# -*- encoding : utf-8 -*-


module LinesHelper
    require 'csv'

  
 

  # page est un tableau de lignes
  #  Cette méthode prend les différents éléments d'une page de listing, en l'occurence
  # les lignes de comptes et qui applique le helper debit_credit aux montants
  def prawn_prepare_page(page)
    page.each  {|l| l[0]=l l[0]; l[4]= debit_credit(l[4]); l[5]=debit_credit(l[5])}
   page.insert(0, ["Date","Référence", "Libellé", "Nature", "Destination", "Débit", "Crédit"])
  end

  # helper pour afficher les actions d'une cash line,
  # la modification doit se faire par transfer si la ligne vient d'un virement
  # ou est en direct si c'est la ligne est une écriture saisie d'un livre de
  # recettes ou de dépenses.
  # TODO cette méthode pourrait être commune avec lines et être également partagée
  # avec bank_lines..
  def line_actions(line)
    html = ' '
      if line.owner_type == 'Transfer'
        html <<  icon_to('modifier.png', edit_organism_transfer_path(@organism, line.owner_id)) unless line.locked?
      else
        html <<  icon_to('modifier.png', edit_book_line_path(line.book_id, line)) unless line.locked?
        html <<  icon_to('supprimer.png', [line.book,line], confirm: 'Etes vous sûr?', method: :delete) unless line.locked?
      end


    content_tag :td, :class=>'icon' do
      html.html_safe
    end

  end



end
