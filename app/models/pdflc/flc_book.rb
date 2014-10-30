#coding: utf-8

module Pdflc
  
  
  # Cette classe permet de produire les fichiers pdf pour un grand livre. 
  # 
  # Par rapport à FlcListing, elle est enrichie de 
  # l'information sur le compte final (to_account). 
  # 
  # la seule méthode revue est draw_pdf qui n'imprime pas les comptes 
  # qui ne sont pas utilisés (ni reports, ni écritures sur la période)
  class FlcBook < Pdflc::FlcListing
    
    attr_accessor :to_account # pour pouvoir les mettre dans le
    # bon ordre
    
    def initialize(options={})
      super
      @to_account = options[:to_account] || @from_account
      @accounts = set_accounts
    end
    
    # draw_pdf crée le pdf puis le remplit pour chacun des comptes qui ont 
    # des reports ou des écritures
    # 
    # Le booléen commence permet de ne pas créer une page vide en 
    # début de texte pour le premier
    # TODO à retirer avec la mise en place d'une page de garde
    #
    def draw_pdf
      @commence = false
      @pdf = Pdflc::FlcPage.new(BOOK_TITLES, BOOK_WIDTHS, BOOK_ALIGNMENTS,
        @reports, @table, @trame, fond:@fond)
      each_account do |acc|
        nb_lines = change_account(acc) 
        if nb_lines == 0 && @pdf.reports.uniq == [0.0]
          next # ni report, ni écriture donc on passe
        else
          @pdf.start_new_page if @commence
          @pdf.draw_pdf(false) 
          # false pour ne pas paginer car fait à la fin
          @commence = true
        end 
         
        
        
        
      end
          
      @pdf.numerote 
      @pdf  

    end 
     
    protected
    
    # passe au compte suivant
    def each_account
      @accounts.each {|a| yield a if block_given?}
    end
    
    # change de compte, ce qui impose de
    # - changer le titre et le sous-titre de la trame;
    # - changer de compte pour la table
    # la méthode retourne le nombre de lignes 
    def change_account(account)
      set_trame_title_and_subtitle(account)
      baa = book_arel(account)
      @table.change_arel(baa)
      @pdf.reports = set_reports(account)
      baa.count 
    end
     
    def set_accounts
      self.from_account, self.to_account = to_account, from_account if
      to_account.number  < from_account.number
      period.accounts.order('number').
        where('number >= ? AND number <= ?',
        from_account.number, to_account.number)
    end
    
    
  end
  
  
end