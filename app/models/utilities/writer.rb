module Utilities
  
  # Cette classe est une interface pour Subscription en relation avec Mask
  class Writer
    
    
    def initialize(subscription)
      @subscription = subscription
      @mask = subscription.mask
    end
    
    # cette méthode est ici et non dans mask car dans la plupart des cas, un masque
    # ne peut pas écrire tout seul une écriture. Il est en général incomplet
    def write(monthyear)
      date = Date.civil(monthyear.year.to_i, monthyear.month.to_i, @subscription.day)
      params = @mask.complete_writing_params(date)
      params[:narration] = "#{params[:narration]} n°#{@subscription.writings.size + 1}"
      @mask.book.in_out_writings.create(params)
    end
    
    # TODO un writer ne devrait écrire que pour l'éxercice en cours
    # en tout cas pas pour un exercice clos.
    
    
    
  end
end