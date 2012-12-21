# coding: utf-8

require 'month_year'
require 'pdf_document/book' 

module Utilities


  # un extrait d'un livre donné avec capacité à calculer les totaux et les soldes.
  # se crée avec deux paramètres : le livre et l'exercice.
  #
  # Un enfant de cette classe MonthlyInOutExtract permet d'avoir des extraits mensuels
  # se créé en appelant new avec un book et une date quelconque du mois souhaité
  # my_hash est un hash :year=>xxxx, :month=>yy
  class InOutExtract

    # utilities::sold définit les méthodes cumulated_debit_before(date) et
    # cumulated_debit_at(date) et les contreparties correspondantes.
    include Utilities::Sold

    include Utilities::ToCsv


    NB_PER_PAGE=30

    attr_reader :book, :titles

    def initialize(book, period)
      @titles = ['Date', 'Réf', 'Libellé', 'Destination', 'Nature', 'Débit', 'Crédit', 'Paiement', 'Support']
      @book = book
      @period = period
    end

    def lines
      @lines ||= @book.compta_lines.extract(@period.start_date, @period.close_date).in_out_lines
    end

    # l'extrait est provisoire si il y a des lignes qui ne sont pas verrouillées
    def provisoire?
      lines.reject {|l| l.locked?}.any?
    end

    def cumulated_at(date, dc)
      @book.cumulated_at(@period.close_date, dc)
    end

    def total_credit
      movement(@period.start_date, @period.close_date, :credit)
    end

    def total_debit
      movement(@period.start_date, @period.close_date, :debit)
    end


    def debit_before
      @book.cumulated_debit_before(@period.start_date)
    end

    def credit_before
      @book.cumulated_credit_before(@period.start_date)
    end

    

    def to_csv(options = {:col_sep=>"\t"})
      CSV.generate(options) do |csv|
        csv << @titles
        lines.each do |line|
          csv << prepare_line(line)
        end
      end
    end
    
    alias compta_lines lines

    def to_pdf
      options = {
        :title=>book.title,
        :subtitle=>"Mois de #{@my.to_format('%B %Y')}",
        :from_date=>@date,
        :to_date=>@date.end_of_month,
        :stamp=> provisoire? ? 'Provisoire' : ''
      }
      period = book.organism.find_period(@date)
      pdf = PdfDocument::Book.new(period, book, options)
      pdf.set_columns ['writings.date AS w_date', 'writings.ref AS w_ref',
        'writings.narration AS w_narration', 'destination_id',
        'nature_id', 'debit', 'credit', 'payment_mode', 'writing_id']
      pdf.set_columns_methods ['w_date', 'w_ref', 'w_narration',
        'destination_id.name', 'nature_id.name', 'debit', 'credit',
        'payment_mode', 'writing_id']
      pdf.set_columns_titles ['Date', 'Réf', 'Libellé', 'Destination', 'Nature', 'Débit', 'Crédit', 'Paiement', 'Support']
      pdf.set_columns_widths([10, 8, 20,10 ,  10, 8, 8,13,13])
      pdf.set_columns_to_totalize [5,6]
       
      pdf
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



    protected

    # prend une ligne comme argument et renvoie un array avec les différentes valeurs
    # préparées : date est gérée par I18n::l, les montants monétaires sont reformatés poru
    # avoir 2 décimales et une virgule,...
    def prepare_line(line)
      [I18n::l(line.date),
        line.ref, line.narration.truncate(25),
        line.destination ? line.destination.name.truncate(22) : '-',
        line.nature ? line.nature.name.truncate(22) : '-' ,
        reformat(line.debit),
        reformat(line.credit),
        "#{line.payment_mode}",
        line.support.truncate(10)
      ]
    end

 

    # remplace les points décimaux par des virgules pour s'adapter au paramétrage
    # des tableurs français
    def reformat(number)
      ActionController::Base.helpers.number_with_precision(number, :precision=>2)
    end


  

  end


end