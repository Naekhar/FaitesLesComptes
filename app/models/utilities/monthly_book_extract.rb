# coding: utf-8




# un extrait d'un mois d'un livre donné avec capacité à calculer les totaux et les soldes
# se créé en appelant new avec un book et une date quelconque du mois souhaité
class Utilities::MonthlyBookExtract

  NB_PER_PAGE=30

  attr_reader :book

  def initialize(book, h)
    @book=book
    @my = MonthYear.new(h)
    @date = @my.beginning_of_month
  end

  def lines
    @lines ||= @book.lines.mois(@date)
  end

  # calcule le nombre de page du listing en divisant le nombre de lignes
  # par un float qui est le nombre de lignes par pages,
  # puis arrondi au nombre supérieur
  def total_pages
    (lines.size/NB_PER_PAGE.to_f).ceil
  end

  def month
    @my.to_format('%B %Y')
  end

  # renvoie les lignes correspondant à la page demandée
  def page(n)
    n = n-1 # pour partir d'une numérotation à zero
    return nil if n > self.total_pages
    @lines[(NB_PER_PAGE*n)..(NB_PER_PAGE*(n+1)-1)].map do |item|
      [
        item.line_date,
        item.ref,
        item.narration.truncate(40),
        item.nature ? item.nature.name.truncate(22) : '-' ,
        item.destination ? item.destination.name.truncate(22) : '-',
        item.debit,
        item.credit
      ]
    end
  end

  def total_debit
    lines.sum(:debit)
  end
  
  def total_credit
    lines.sum(:credit)
  end

  def debit_before
    @book.cumulated_debit_before(@date)
  end

  def credit_before
    @book.cumulated_credit_before(@date)
  end

  def sold
    credit_before + total_credit - debit_before - total_debit
  end


  def to_csv(options)
    CSV.generate(options) do |csv|
      csv << ['Date', 'Réf', 'Libellé', 'Destination', 'Nature', 'Débit', 'Crédit', 'Paiement']
      lines.each do |line|
        csv << [I18n::l(line.line_date), line.ref, line.narration, "#{line.destination_name}",
      "#{line.nature_name}",
      line.debit.to_s.gsub('.', ','), line.credit.to_s.gsub('.', ','), # gsub pour avoir des ,
      "#{line.payment_mode}"]
      end
    end
  end

   # indique si le listing doit être considéré comme un brouillard
   # ou une édition définitive.
   #
   # Cela se fait en regardant si toutes les lignes sont locked?
   #
   # TODO attention avec les livres virtuels tels que CashBook
   # il faut peut être que transfer ait un champ locked?
   def brouillard?
     if @lines.any? {|l| !l.locked? }
       return true
     else
       return false
     end
   end



  end
