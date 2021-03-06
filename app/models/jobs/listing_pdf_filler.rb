module Jobs
  
  # Cette classe est un delayed job qui a pour fonction de préparer le 
  # contenu du fichier pdf pour un livre de recettes ou de dépenses.
  #
  # Les arguments sont 
  # - db_name : la base de données
  # - export_pdf_id : qui est l'id du record export_pdf
  # - et des options qui doivent donner l'id de l'exercice (:period_id), 
  #   et :an et :mois qui permettent de savoir quel mois est demandé.
  #   
  # L'utilisation se fait dans le controller (voir natures_controller)
  # Delayed::Job.enqueue Jobs::WritingsPdfFiller.new(@organism.database_name, 
  # export_pdf.id, {period_id:@period.id, destination:0})
  #
  # L'argument database_name permet de gérer les jobs dans la schéma Public
  # alors que les enregistrements sont dans les schémas particuliers.
  # Chaque appel de méthode se fait donc par un appel à Apartment::Database.process(dbname) 
  # et un bloc.
  # 
  class ListingPdfFiller < BasePdfFiller
        
    protected
    
    # fournit la variable d'instance document et remplit l'élément account
    def set_document(options)
      Rails.logger.debug options.inspect
      @document = Compta::Listing.new(options[:params_listing].
          permit(:from_date_picker, :to_date_picker))
      @document.account_id = options[:account_id]
      Rails.logger.debug @document.inspect
    end
    
    
    
  end
  
  
end