class Listing < ActiveRecord::Base
  belongs_to :organism
  has_many :lines, dependent: :destroy
  has_many :bank_extracts, dependent: :destroy



  # Méthode qui donne le montant du dernier solde bancaire
  # par ordre de date
  # 
  def extract_sold
    self.bank_extracts.order(:end_date).last.end_sold
  rescue
    0
  end

end
