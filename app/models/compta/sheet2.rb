# coding: utf-8

require 'yaml'



# Sheet est destinées à éditer une liste de rubriks
# Le but est de construire des sous parties de bilan ou de comtpe de résultats
# Les arguments sont period, une page qui est une partie d'un fichier yml.
# Concrètement la classe Nomenclature lit un fichier nomenclature.yml. et engendre 
# ainsi des folios (typiquement :actif, :passif, :resultat, :benevolat), lesquels ont
# des rubriks
#
# Le fichier a différentes parties : actif, passif, exploitation, ...
# Nomenclature a une méthode sheet qui crée un objet Sheet en transmettant
# period,  les informations nécessaires et le nom du document
#
# Exemple, extrait de nomenclature.yml
# :actif:                      -> le document
#    :title: Bilan Actif        -> son titre
#    :sens: :actif              -> son sens
#    :rubriks:                  -> la liste des rubriques   
#      :Immobilisations incorporelles:            -> première sous rubrique (ce sera une rubriks)
#        :Frais d'établissement: '201 -2801'       -> une rubrik
#        :Frais de recherche et développement: 203 -2803
#        :Fonds commercial#': 206 207 -2807 -2906 -2907
#        :Autres: 208 -2808 -2809
#      :Immobilisations corporelles:              -> deuxième sous rubrique
#
# Le document est donc composé de rubriks, eux même composé de rubrik
# Voir les classes correspondantes
# 
# 
# Dans initialize, les arguments sont recopiés, puis on appelle parse_page
# qui va parser les instructions du document demandé.
#
#
# #total_general est une méthode qui renvoie la rubriks principale de sheet
#
# sens permet de savoir si on est un document avec une logique d'actif ou de passif
# Cette logique permet en fait de choisir si les nombres credit ou débit sont positifs
# doc est le nom du document.
#  
#
module Compta

  class Sheet2
    
    include Utilities::ToCsv
    include ActiveModel::Validations
    
    attr_accessor :total_general, :sens, :name, :list_rubriks, :folio

  #  TODO : mettre ce validate dans le modèle Folio
  #  validates :sens, :inclusion=>{:in=>[:actif, :passif]}


    # page est un des éléments du fichier yml décrivant le document.
    # 
    # Concrètement page est :actif, :passif, :resultat, :benevolat.
    # name sera le nom du document (par exemple Compte de Résultats)
    # 
    # parse_page lit les instructions de la page et construit @total_general
    #
    def initialize(period, folio)
      @folio = folio
      @period = period
      
      @name = folio.name
      # parse_page
    end

    
# 
    # utilisé pour le csv de l'option show
    def to_csv(options = {col_sep:"\t"})
      CSV.generate(options) do |csv|
        csv << [name.capitalize] # par ex Actif
        csv << entetes  # la ligne des titres
        folio.root.fetch_lines(@period).each do |rubs|
          csv << (@sens==:actif ? prepare_line(rubs.total_actif(@period)) : format_line(rubs.total_passif(@period)))
        end
      end
    end


    # utilisé pour le csv de l'action index
    def to_index_csv(options = {col_sep:"\t"})
      CSV.generate(options) do |csv|
        csv << [@name.capitalize] # par ex Actif
        csv << (@sens == :actif ? %w(Rubrique Brut Amort Net Précédent) : ['Rubrique', '', '',  'Montant', 'Précédent']) # la ligne des titres
        folio.root.fetch_rubriks_with_rubrik.each do |rubs|
          csv << prepare_line(rubs.total_actif(@period))
        end
      end
    end
 
    def to_index_xls(options = {col_sep:"\t"})
      to_index_csv(options).encode("windows-1252") 
    end



    # fait une édition de sheet ce qui reprend des titres puis insère les éléments
    #
    def to_pdf(options = {})
      options[:title] =  name.to_s 
      options[:documents] = @page
      Editions::Sheet.new(@period, self, options)
    end

    def to_detailed_pdf(options = {})
      options[:title] =  name.to_s
      options[:documents] = @page
      Editions::DetailedSheet.new(@period, self, options)
    end

    def detailed_lines(page_number=1)
      total_general.fetch_lines(page_number)
    end

    def render_pdf
      to_pdf.render 
    end


    protected

    # appelé par initialize, construit l'ensemble des rubriks qui seront utilisées pour
    # les différentes parties du document (avec à chaque fois le sous total affiché)
    # puis, utilise ces rubriques, pour faire le total_general.
    #
    # S'appuie sur collect_rubriks pour faire la récursivité nécessaire
#    def parse_page
#      @sens = folio.sens
#      sous_totaux = @list_rubriks[:rubriks].map do  |k,v| 
#        collect_rubriks(k,v,@sens)
#      end
#      @total_general = Compta::Rubriks.new(@period, @list_rubriks[:title] , sous_totaux) 
#    end

#    def collect_rubriks(cle, instruction, sens)
#      list = instruction.map do |k,v|
#        v.is_a?(Hash) ? collect_rubriks(k,v,sens) : Compta::Rubrik.new(@period, k, @sens, v)
#      end
#      Compta::Rubriks.new(@period, cle, list)
#    end


    # prepare line sert à effacer les montant brut et amortissement pour ne garder
    # que le net.
    # Utile pour le passif d'un bilan et pour les comptes de résultats qui n'ont pas
    # la même logique qu'une page actif.
    # prepare_line assure également la mise en forme des lignes au format français
    # pour les exportations vers le tableur.
    def prepare_line(line)
      if @sens != :actif
        line[1] = line[2]= ''
      end
      format_line(line)
    end

    # utilise le helper numeric_with_precision pour gérer la transmission
    # des données vers les pdf et les csv.
    def format_line(line)
      line.collect do |element|
        if element.is_a? Numeric
          ActionController::Base.helpers.number_with_precision(element, :precision=>2)
        else
          element
        end
      end
    end

    # prépare les entêtes utilisés pour le fichier csv
    def entetes
      @sens == :actif ? %w(Rubrique Brut Amort Net Précédent) : %w(Rubrique Montant Précédent)
    end

  

  end





end