# -*- encoding : utf-8 -*-
require 'strip_arguments'
# Room est un modèle qui se situe dans le schéma public et qui sert à
# enregistrer les noms des bases de données puisque chaque organisme dispose de
# sa propre base de donnée.
#
# Voir les commentaires sur versions_controller pour la gestion des migrations et
# des versions
#
class Room < ActiveRecord::Base  
  
  has_many :holders, dependent: :destroy
   
  attr_accessible :database_name

  strip_before_validation :database_name 
    
  validates :database_name, presence:true, :format=>{:with=>/\A[a-z][a-z0-9]*(_[0-9]*)?\z/}, uniqueness:true
  
  
  after_create :create_db, :connect_to_organism
  before_update :change_schema_name, :if=>:database_name_changed?
  after_destroy :destroy_db
  
  # renvoie le propriétaire de la base
  def owner
    holders.where('status = ?', 'owner').first.user
  end
  
  # renvoie l'organisme associé à la base
  def organism
    Apartment::Database.process(database_name) {Organism.first}
  end
  
  # look_for permet de chercher quelque chose dans la pièce
  # Le block indique ce qu'on cherche
  #
  # Usage possible look_for {Organism.first} mais il vaut mieux utiliser la méthode organism
  #
  def look_for(&block)
    Apartment::Database.process(database_name) {block.call}
  end  

  # Vérifie que la base de données enregistrant les Room est bien dans la bonne version
  #
  # Il y a le cas où la base principale (celle qui enregistre User et Room) n'est
  # elle même pas à jour. Par exemple, si on démarre le serveur avec une nouvelle
  # version. 
  # 
  # En fait inactif actuellement puisque je migre les bases sur Heroku
  # Mais pourrait redevenir d'actualité si on prévoit des restaurations de schémas
  #
  def self.version_update?
    arm = ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations_paths)
    arm.pending_migrations.any? ? false : true
  end

  # relative_version compare la version de l'organisme
  # et indique si cet organisme est en avance ou en retard par rapport
  # aux migrations qui sont enregistrées dans Room
  #
  # La valeur retournée est un hash avec l'id de la Room et un symbole indiquant
  # l'état de la migration par rapport à la base principale (Room).
  #
  # nil si la base n'est pas trouvée.
  def relative_version
    room_last_migration  = Room.jcl_last_migration
    organism_last_migration = look_for {Organism.migration_version}
    if organism_last_migration
      v =:same_migration if room_last_migration == organism_last_migration
      v = :late_migration if room_last_migration > organism_last_migration
      v = :advance_migration if room_last_migration < organism_last_migration
    else
      v = :no_base
    end
    v
  end

  def late?
    relative_version == :late_migration ? true : false
  end

  def no_base?
    relative_version == :no_base ? true : false
  end

  def advanced?
    relative_version == :advance_migration ? true : false
  end

  def up_to_date?
    relative_version == :same_migration ? true : false
  end

  # renvoie la dernière migration de la base principale (Room et User)
  def self.jcl_last_migration
    Apartment::Database.process() do
      ActiveRecord::Migrator.new(:up, ActiveRecord::Migrator.migrations_paths).migrated.last
    end
  end

  # se connecte à l'organisme correspondant à la base de données
  #
  # retourne true ou false
  def connect_to_organism
    Apartment::Database.switch(database_name)
  end

  alias enter connect_to_organism

  # La méthode de classe enter est un raccouci pour find(id).enter
  def self.enter(id)
    r = Room.find_by_id(id)
    if r
      r.enter
    else
      return nil
    end
  end

  
  # le but de clone_db est de pouvoir faire des sauvegardes à un moment voulu d'une base de données
  #
  # La logique de clone est donc de créer une nouvelle db appartenant au même user
  # mais avec comme base de données le database_name incrémenté
  #
  # Cette méthode est appelée par clones_controller pour permettre de créer un  clone avec un commentaire
  # 
  def clone_db(comment = nil)
    # lit le database_name et calcule son incrémentation
    new_db_name = timestamp_db_name
    Room.transaction do
      # crée le nouveau database_name
      Apartment::Database.create(new_db_name)
      # puis on copie la totalité des tables
      Apartment::Database.copy_schema(database_name, new_db_name)
      # on change le nom de organism#database_name dans organism pour refléter new_db_name
      # et on ajoute le commentaire
      Apartment::Database.process(new_db_name) do
        Rails.logger.info 'Dans clone_db, partie Apartment::Database.process'
        o = Organism.first
        
        o.database_name = new_db_name
        o.comment = comment
        Rails.logger.warn o.errors.messages unless o.valid?
        o.save!
      end
      # on finit en créant la nouvelle room
      clone_room(new_db_name)
      

    end 
  end

  protected
  
  # clone_room est appelé par clone_db pour créer une room ayant les mêmes holder
  # que la room actuelle mais avec room_id pointant sur la nouvelle Room
  def clone_room(new_db_name)
    # on crée la Room
    r = Room.create!(:database_name=>new_db_name)
    # puis pour chaque holder on duplique
    holders.each {|h| newholder = h.dup; newholder.room_id = r.id; newholder.save!}
  end

  
  # crée un database_name préfixé par un timestamp
  # à partir du database_name existant, soit en préfixant le nom avec un nouveau 
  # timestamp, soit en changeant le timestamp
  #
  def timestamp_db_name
    if database_name =~ /^([a-zA-Z0-9]*)_\d{14}$/
      $1 + '_' + Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      database_name + '_' + Time.now.utc.strftime("%Y%m%d%H%M%S")
    end
  end




  def create_db
    if Apartment::Database.db_exist?(database_name)
      Rails.logger.info "Après création de Room :la base #{database_name} existe déjà"
      Apartment::Database.switch(database_name)
    else
      Rails.logger.info "Après création de Room ; création de la base #{database_name}"
      Apartment::Database.create(database_name)
    end
  end

  def destroy_db
    Rails.logger.info "Destruction de la base #{database_name}"
    Apartment::Database.drop(database_name) 
    Apartment::Database.switch # pour revenir à la base de données par défaut
  end 

  # Cette action ne devrait a priori jamais être appelée.
  # 
  # Change le schéma de la base de données (postgresql uniquement) puis met à jour
  # le champ database_name de Organism (qui doit être synchronisé avec Room)
  def change_schema_name
    result = Apartment::Database.rename_schema( database_name_was, database_name)
    return result if result == false
    Apartment::Database.switch(database_name)
    Organism.first.update_attribute(:database_name, database_name)
  end


 

end
