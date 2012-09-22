# coding: utf-8

# les livres de recettes et de dépenses
class IncomeOutcomeBook < Book

  # l'affichage des montants et des lignes dans la vue ne doit pas prendre en
  # compte les lignes de contrepartie d'où l'utilisation du scope inouts
  # plutôt que lines pour cumulated_at
  def cumulated_at(date, dc)
    p = organism.find_period(date)
    p ? inouts.period(p).where('line_date <= ?', date).sum(dc) : 0
  end
end