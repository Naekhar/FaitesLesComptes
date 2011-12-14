# -*- encoding : utf-8 -*-
module LinesHelper
  def debit_credit(montant)
    if montant > -0.01 && montant < 0.01
      '-'
    else
      number_with_precision(montant, :precision=> 2)
    end
  rescue
    ''
  end

 def submenu_helper(book)
    t=['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',' Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']
    content_tag :div do
    r=''
    t.each_with_index do |mois, i|
        r += concat(link_to(mois, book_lines_path(book, "mois"=> i)))
    end
    r
    end
 end
end
